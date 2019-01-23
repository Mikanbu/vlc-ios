/*****************************************************************************
 * VLCOneDriveTableViewController.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *          Pierre Sagaspe <pierre.sagaspe # me.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveTableViewController.h"
#import "VLCOneDriveController.h"
#import "VLCCloudStorageTableViewCell.h"
#import "VLCPlaybackController.h"
#import "VLCProgressView.h"
#import "UIDevice+VLC.h"
#import "NSString+SupportedMedia.h"
#import "VLCConstants.h"

@interface VLCOneDriveTableViewController () <VLCCloudStorageDelegate>
{
    VLCOneDriveController *_oneDriveController;
}
@end

@implementation VLCOneDriveTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self prepareOneDriveControllerIfNeeded];
    self.controller = _oneDriveController;
    self.controller.delegate = self;

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"OneDriveWhite"]];

#if TARGET_OS_IOS
    [self.cloudStorageLogo setImage:[UIImage imageNamed:@"OneDriveWhite"]];

    [self.cloudStorageLogo sizeToFit];
    self.cloudStorageLogo.center = self.view.center;
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateViewAfterSessionChange];
    self.authorizationInProgress = NO;
    [self prepareOneDriveControllerIfNeeded];
}

- (void)prepareOneDriveControllerIfNeeded
{
    if (!_oneDriveController) {
        _oneDriveController = [VLCOneDriveController sharedInstance];
        _oneDriveController.presentingViewController = self;
    }
}

#pragma mark - generic interface interaction

- (void)goBack
{
    NSString *currentItemID = _oneDriveController.currentItem.id;

    if (currentItemID && ![currentItemID isEqualToString:_oneDriveController.rootItemID]) {
        if (!_oneDriveController.parentItem
            || [_oneDriveController.rootItemID isEqualToString:_oneDriveController.parentItem.id]) {
            _oneDriveController.currentItem = nil;
        } else {
            _oneDriveController.currentItem = [[ODItem alloc] initWithDictionary:_oneDriveController.parentItem.dictionaryFromItem];
            _oneDriveController.parentItem.id = _oneDriveController.parentItem.parentReference.id;
        }
        [self.activityIndicator startAnimating];
        [_oneDriveController loadODItems];
    } else {
        // We're at root, we need to pop the view
        [self.navigationController popViewControllerAnimated:YES];
    }
    return;
}

#pragma mark - table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"OneDriveCell";

    VLCCloudStorageTableViewCell *cell = (VLCCloudStorageTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [VLCCloudStorageTableViewCell cellWithReuseIdentifier:CellIdentifier];

    NSArray *items = _oneDriveController.currentListFiles;

    if (indexPath.row < items.count) {
        cell.oneDriveFile = items[indexPath.row];
        cell.delegate = self;
    }

    return cell;
}

#pragma mark - table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *items = _oneDriveController.currentListFiles;
    NSInteger row = indexPath.row;
    if (row >= items.count)
        return;

    ODItem *selectedItem = items[row];

    if (selectedItem.folder) {
        [self.activityIndicator startAnimating];
        _oneDriveController.parentItem = _oneDriveController.currentItem;
        _oneDriveController.currentItem = selectedItem;
        [_oneDriveController loadODItems];
        self.title = selectedItem.name;
    } else {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kVLCAutomaticallyPlayNextItem]) {
            NSURL *url = [NSURL URLWithString:selectedItem.webUrl];
            /* stream file */
            VLCMediaList *mediaList = [[VLCMediaList alloc] initWithArray:@[[VLCMedia mediaWithURL:url]]];
            [self streamMediaList:mediaList startingAtIndex:0
                subtitlesFilePath:[_oneDriveController configureSubtitleWithFileName:selectedItem.name
                                                                         folderItems:items]];
        } else {
            [self streamMediaList:[self createMediaList] startingAtIndex:row subtitlesFilePath:nil];
        }
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (void)streamMediaList:(VLCMediaList *)mediaList startingAtIndex:(NSInteger)startIndex subtitlesFilePath:(NSString *)subtitlesFilePath
{
    if (mediaList.count <= 0) {
        NSLog(@"VLCOneDriveTableViewController: Empty or wrong mediaList");
        return;
    }

    VLCPlaybackController *vpc = [VLCPlaybackController sharedInstance];
    vpc.fullscreenSessionRequested = NO;
    [vpc playMediaList:mediaList firstIndex:startIndex subtitlesFilePath:subtitlesFilePath];
}

- (VLCMediaList *)createMediaList
{
    NSUInteger counter = 0;
    NSArray *folderItems = _oneDriveController.currentListFiles;
    VLCMediaList *mediaList = [[VLCMediaList alloc] init];
    for (ODItem *item in folderItems) {
        if (item.folder || [item.name isSupportedSubtitleFormat])
            continue;
        NSURL *url = [NSURL URLWithString:item.dictionaryFromItem[@"@content.downloadUrl"]];
        if (url) {
            [mediaList addMedia:[VLCMedia mediaWithURL:url]];
            NSString *subtitlePath = [_oneDriveController configureSubtitleWithFileName:item.name folderItems:folderItems];
            if (subtitlePath) {
                [[mediaList mediaAtIndex:counter] addOptions:@{ kVLCSettingSubtitlesFilePath : subtitlePath }];
            }
            counter ++;
        }
    }
    return mediaList;
}

- (void)playAllAction:(id)sender
{
    [self streamMediaList:[self createMediaList] startingAtIndex:0 subtitlesFilePath:nil];
}

#pragma mark - login dialog

- (void)loginAction:(id)sender
{
    if (![_oneDriveController isAuthorized]) {
        self.authorizationInProgress = YES;
        [_oneDriveController loginWithViewController:self];
    } else
        [_oneDriveController logout];
}

#pragma mark - onedrive controller delegation

- (void)sessionWasUpdated
{
    [self updateViewAfterSessionChange];
}

#pragma mark - cell delegation

#if TARGET_OS_IOS
- (void)triggerDownloadForCell:(VLCCloudStorageTableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    ODItem *selectedItem = _oneDriveController.currentListFiles[indexPath.row];

    if (selectedItem.size < [[UIDevice currentDevice] VLCFreeDiskSpace].longLongValue) {
        /* selected item is a proper file, ask the user if s/he wants to download it */

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DROPBOX_DOWNLOAD", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"DROPBOX_DL_LONG", nil),
                                                                                          selectedItem.name,
                                                                                          [[UIDevice currentDevice] model]]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *downloadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_DOWNLOAD", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction *alertAction){
                                                             [_oneDriveController startDownloadingODItem:selectedItem];
                                                         }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_CANCEL", nil)
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];


        [alertController addAction:downloadAction];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DISK_FULL", nil)
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"DISK_FULL_FORMAT", nil),
                                                                                          selectedItem.name,
                                                                                          [[UIDevice currentDevice] model]]
                                                                          preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"BUTTON_OK", nil)
                                                                 style:UIAlertActionStyleCancel
                                                               handler:nil];

        [alertController addAction:okAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#endif

@end
