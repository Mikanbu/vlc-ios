/*****************************************************************************
 * VLCOneDriveController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014-2015 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCOneDriveTableViewController.h"
#import "VLCOneDriveObject.h"

#define VLCOneDriveControllerSessionUpdated @"VLCOneDriveControllerSessionUpdated"

@interface VLCOneDriveController : VLCCloudStorageController

@property (readonly) BOOL activeSession;
@property (nonatomic, readwrite) ODItem *currentItem;
@property (nonatomic, readwrite) ODItem *parentItem;
@property (nonatomic, readonly) NSString *rootItemID;
@property (nonatomic) UIViewController *presentingViewController;

+ (VLCOneDriveController *)sharedInstance;

- (void)loginWithViewController:(UIViewController*)presentingViewController;

- (void)startDownloadingODItem:(ODItem *)item;

- (NSString *)configureSubtitleWithFileName:(NSString *)fileName folderItems:(NSArray *)folderItems;

- (void)loadODItems;
- (void)loadODItemsWithCompletionHandler:(void (^)(void))completionHandler;

@end
