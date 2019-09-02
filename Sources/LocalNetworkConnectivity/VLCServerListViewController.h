/*****************************************************************************
 * VLCLocalServerListViewController.h
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2013 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Felix Paul Kühne <fkuehne # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class VLCServices;

@interface VLCServerListViewController : UIViewController

- (instancetype)initWithServices:(NSObject *)services;

@end

NS_ASSUME_NONNULL_END
