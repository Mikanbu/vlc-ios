/*****************************************************************************
 * VLCOneDriveController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveController.h"
#import "VLCOneDriveConstants.h"
#import "VLCOneDriveObject.h"
#import "UIDevice+VLC.h"
#import "NSString+SupportedMedia.h"
#import "VLCHTTPFileDownloader.h"

/* the Live SDK doesn't have an umbrella header so we need to import what we need */
#import "LiveConnectClient.h"

/* include private API headers */
#import "LiveApiHelper.h"
#import "LiveAuthStorage.h"
#import <OneDriveSDK.h>

@interface VLCOneDriveController ()
{
    LiveConnectClient *_liveClient;
    NSString *_folderId;
    NSArray *_liveScopes;
    BOOL _activeSession;
    BOOL _userAuthenticated;

    NSMutableArray *_pendingDownloads;
    BOOL _downloadInProgress;

    CGFloat _averageSpeed;
    CGFloat _fileSize;
    NSTimeInterval _startDL;
    NSTimeInterval _lastStatsUpdate;

    ODClient *_oneDriveClient;
    NSMutableArray *_currentItems;
    VLCHTTPFileDownloader *_fileDownloader;
}

@end

@implementation VLCOneDriveController

+ (VLCCloudStorageController *)sharedInstance
{
    static VLCOneDriveController *sharedInstance = nil;
    static dispatch_once_t pred;

    dispatch_once(&pred, ^{
        sharedInstance = [[VLCOneDriveController alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];

    if (!self)
        return self;
    [self restoreFromSharedCredentials];
    _oneDriveClient = [ODClient loadCurrentClient];
    [self setupSession];
    return self;
}

- (void)setupSession
{
    // using this and not clientWithCompletion since it calls authenticatedClientWithCompletion
    // that makes the ui pop
    _parentItem = nil;
    _currentItem  = nil;
    _rootItemID = nil;
    _currentItems = [[NSMutableArray alloc] init];
    if (_oneDriveClient) {
        NSLog(@"_onedrive exists!");
        _activeSession = YES;
    }
}

#pragma mark - authentication

- (BOOL)activeSession
{
    return _activeSession;
}

- (void)loginWithViewController:(UIViewController *)presentingViewController
{
    _presentingViewController = presentingViewController;
    [ODClient authenticatedClientWithCompletion:^(ODClient *client, NSError *error) {
        if (error) {
            [self authFailed:error];
            return;
        }
        // with auth,     [self setupSession]; is not called so with a logout,
        // currentItems is set to nil therefore not initialized anymore since it is initialized only on init
        _oneDriveClient = client;
        [self authSuccess:_oneDriveClient error:error];
    }];
}

- (void)logout
{
    [_oneDriveClient signOutWithCompletion:^(NSError *error) {
        NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
        [ubiquitousStore removeObjectForKey:kVLCStoreOneDriveCredentials];
        [ubiquitousStore synchronize];
        _oneDriveClient = nil;
        _activeSession = NO;
        _userAuthenticated = NO;
        _currentItem  = nil;
        _currentItems = nil;
        _rootItemID = nil;
        _parentItem = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_presentingViewController) {
                [_presentingViewController.navigationController popViewControllerAnimated:YES];
            }
        });
    }];
}

- (NSArray *)currentListFiles
{
    return [_currentItems copy];
}

- (BOOL)isAuthorized
{
    //    return _liveClient.session != NULL;
    // bubu: not really, must be a better way to check current status
    return _oneDriveClient != nil;
}

- (void)authSuccess:(ODClient *)client error:(NSError *)error
{
    APLog(@"OneDrive: authCompleted");

    _activeSession = YES;
    _userAuthenticated = YES;
//    [self loadODItems];
    [self setupSession];

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)]) {
            dispatch_async(dispatch_get_main_queue(),^ {
                [self.delegate performSelector:@selector(sessionWasUpdated)];
            });
        }

    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCOneDriveControllerSessionUpdated object:self];

    [self shareCredentials];
}

- (void)authFailed:(NSError *)error
{
    _activeSession = NO;

    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(sessionWasUpdated)])
            [self.delegate performSelector:@selector(sessionWasUpdated)];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:VLCOneDriveControllerSessionUpdated object:self];
}

- (void)shareCredentials
{
    /* share our credentials */
    LiveAuthStorage *authStorage = [[LiveAuthStorage alloc] initWithClientId:kVLCOneDriveClientID];
    NSString *credentials = [authStorage refreshToken];
    if (credentials == nil)
        return;

    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore setString:credentials forKey:kVLCStoreOneDriveCredentials];
    [ubiquitousStore synchronize];
}

- (BOOL)restoreFromSharedCredentials
{
    LiveAuthStorage *authStorage = [[LiveAuthStorage alloc] initWithClientId:kVLCOneDriveClientID];
    NSUbiquitousKeyValueStore *ubiquitousStore = [NSUbiquitousKeyValueStore defaultStore];
    [ubiquitousStore synchronize];
    NSString *credentials = [ubiquitousStore stringForKey:kVLCStoreOneDriveCredentials];
    if (!credentials)
        return NO;

    [authStorage setRefreshToken:credentials];
    return YES;
}

#pragma mark - listing

- (void)requestDirectoryListingAtPath:(NSString *)path
{
    [self loadODItems];
}

- (void)prepareODItems:(NSArray<ODItem *> *)items
{
    for (ODItem *item in items) {
        if (!_rootItemID) {
            _rootItemID = item.parentReference.id;
        }

        if (![_currentItems containsObject:item.id] && ([item.name isSupportedFormat] || item.folder)) {
            [_currentItems addObject:item];
        } else {
            NSLog(@"Ignored this file: %@", item.name);
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate) {
            [self.delegate performSelector:@selector(mediaListUpdated)];
        }
    });

}

- (void)loadODItemsWithCompletionHandler:(void (^)(void))completionHandler
{
    NSString *itemID = _currentItem ? _currentItem.id : @"root";
    ODChildrenCollectionRequest * request = [[[[_oneDriveClient drive] items:itemID] children] request];

    // Clear all current
    [_currentItems removeAllObjects];

    [request getWithCompletion:^(ODCollection *response, ODChildrenCollectionRequest *nextRequest, NSError *error) {
        if (!error) {
            [self prepareODItems:response.value];
            if (completionHandler) {
                completionHandler();
            }
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[error localizedFailureReason]
                                                                                     message:[error localizedDescription]
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction *alertAction){
                                                                 if (_presentingViewController) {
                                                                     // maybe pop only when itemID = @"root"?
                                                                     [_presentingViewController.navigationController popViewControllerAnimated:YES];
                                                                 }
                                                             }];

            [alertController addAction:okAction];

            if (_presentingViewController) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_presentingViewController presentViewController:alertController animated:YES completion:nil];
                });
            }
        }
    }];
}

- (void)loadODItems
{
    [self loadODItemsWithCompletionHandler:nil];
}

- (void)loadThumbnails:(NSArray<ODItem *> *)items
{
    for (ODItem *item in items) {
        if ([item thumbnails:0]) {
            [[[[[_oneDriveClient.drive items:item.id] thumbnails:@"0"] small] contentRequest]
             downloadWithCompletion:^(NSURL *location, NSURLResponse *response, NSError *error) {
                 if (!error) {
                 }
             }];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //        if (self.delegate) {
        //            [self.delegate performSelector:@selector(mediaListUpdated)];
        //        }
    });
}

#pragma - subtitle

- (NSString *)configureSubtitleWithFileName:(NSString *)fileName folderItems:(NSArray *)folderItems
{
    NSString *subtitleURL = nil;
    NSString *subtitlePath = [self _searchSubtitle:fileName folderItems:folderItems];

    if (subtitlePath)
        subtitleURL = [self _getFileSubtitleFromServer:[NSURL URLWithString:subtitlePath]];

    return subtitleURL;
}

- (NSString *)_searchSubtitle:(NSString *)fileName folderItems:(NSArray *)folderItems
{
    NSString *urlTemp = [[fileName lastPathComponent] stringByDeletingPathExtension];
    NSString *itemPath = nil;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name contains[c] %@", urlTemp];
    NSArray *results = [folderItems filteredArrayUsingPredicate:predicate];

    for (ODItem *item in results) {
        if ([item.name isSupportedSubtitleFormat]) {
            itemPath = item.dictionaryFromItem[@"@content.downloadUrl"];
        }
    }
    return itemPath;
}

- (NSString *)_getFileSubtitleFromServer:(NSURL *)subtitleURL
{
    NSString *FileSubtitlePath = nil;
    NSData *receivedSub = [NSData dataWithContentsOfURL:subtitleURL]; // TODO: fix synchronous load

    if (receivedSub.length < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *directoryPath = searchPaths[0];
        FileSubtitlePath = [directoryPath stringByAppendingPathComponent:[subtitleURL lastPathComponent]];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
            //create local subtitle file
            [fileManager createFileAtPath:FileSubtitlePath contents:nil attributes:nil];
            if (![fileManager fileExistsAtPath:FileSubtitlePath]) {
                APLog(@"file creation failed, no data was saved");
                return nil;
            }
        }
        [receivedSub writeToFile:FileSubtitlePath atomically:YES];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil), [subtitleURL lastPathComponent], [[UIDevice currentDevice] model]]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];

        [alertController addAction:okAction];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
    }

    return FileSubtitlePath;
}

#pragma mark - file handling

- (BOOL)canPlayAll
{
    return YES;
}

- (void)startDownloadingODItem:(ODItem *)item
{
    if (item == nil)
        return;
    if (item.folder)
        return;

    if (!_pendingDownloads)
        _pendingDownloads = [[NSMutableArray alloc] init];
    [_pendingDownloads addObject:item];

    [self _triggerNextDownload];
}

- (void)downloadODItem:(ODItem *)item
{
#if TARGET_OS_IOS
    if (!_fileDownloader) {
        _fileDownloader = [[VLCHTTPFileDownloader alloc] init];
        _fileDownloader.delegate = self;
    }
    [_fileDownloader downloadFileFromURL:[NSURL URLWithString:item.dictionaryFromItem[@"@content.downloadUrl"]]
                            withFileName:item.name];
#endif
}

- (void)_triggerNextDownload
{
    if (_pendingDownloads.count > 0 && !_downloadInProgress) {
        _downloadInProgress = YES;
        [self downloadODItem:_pendingDownloads[0]];
        [_pendingDownloads removeObjectAtIndex:0];

        if ([self.delegate respondsToSelector:@selector(numberOfFilesWaitingToBeDownloadedChanged)])
            [self.delegate numberOfFilesWaitingToBeDownloadedChanged];
    }
}

- (void)downloadStarted
{
    _startDL = [NSDate timeIntervalSinceReferenceDate];
    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStarted)])
        [self.delegate operationWithProgressInformationStarted];
}

- (void)downloadEnded
{
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString(@"GDRIVE_DOWNLOAD_SUCCESSFUL", nil));

    if ([self.delegate respondsToSelector:@selector(operationWithProgressInformationStopped)])
        [self.delegate operationWithProgressInformationStopped];

    _downloadInProgress = NO;
    [self _triggerNextDownload];
}

- (void)downloadFailedWithErrorDescription:(NSString *)description
{
    APLog(@"VLCOneDriveController: Download failed (%@)", description);
}

- (void)progressUpdatedTo:(CGFloat)percentage receivedDataSize:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    [self progressUpdated:percentage];
    [self calculateRemainingTime:receivedDataSize expectedDownloadSize:expectedDownloadSize];
}

- (void)progressUpdated:(CGFloat)progress
{
    if ([self.delegate respondsToSelector:@selector(currentProgressInformation:)])
        [self.delegate currentProgressInformation:progress];
}

- (void)calculateRemainingTime:(CGFloat)receivedDataSize expectedDownloadSize:(CGFloat)expectedDownloadSize
{
    CGFloat lastSpeed = receivedDataSize / ([NSDate timeIntervalSinceReferenceDate] - _startDL);
    CGFloat smoothingFactor = 0.005;
    _averageSpeed = isnan(_averageSpeed) ? lastSpeed : smoothingFactor * lastSpeed + (1 - smoothingFactor) * _averageSpeed;

    CGFloat RemainingInSeconds = (expectedDownloadSize - receivedDataSize)/_averageSpeed;

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:RemainingInSeconds];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    NSString  *remaingTime = [formatter stringFromDate:date];
    if ([self.delegate respondsToSelector:@selector(updateRemainingTime:)])
        [self.delegate updateRemainingTime:remaingTime];
}

#pragma mark - onedrive object delegation

- (void)folderContentLoaded:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate performSelector:@selector(mediaListUpdated)];
}

- (void)folderContentLoadingFailed:(NSError *)error sender:(VLCOneDriveObject *)sender
{
    APLog(@"folder content loading failed %@", error);
}

- (void)fullFolderTreeLoaded:(VLCOneDriveObject *)sender
{
    if (self.delegate)
        [self.delegate performSelector:@selector(mediaListUpdated)];
}

@end
