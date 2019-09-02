/*****************************************************************************
 * VLCCloudServicesTableViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2014 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # googlemail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>

NS_SWIFT_NAME(CloudServicesTableViewController)
@interface VLCCloudServicesTableViewController : UITableViewController

@property (nonatomic, readonly, copy) NSString *detailText;
@property (nonatomic, readonly) UIImage *cellImage;

// Since Swift seems to ignore Swift type parameter such as VLCServices,
// we pass an abstraction in order for it to be visible in Swift.
- (instancetype)initWithServices:(NSObject *)services;

@end
