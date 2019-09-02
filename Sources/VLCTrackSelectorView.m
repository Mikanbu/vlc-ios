/*****************************************************************************
 * VLCTrackSelectorView.m
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2017 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

#import "VLCTrackSelectorView.h"

#import "VLCPlaybackService.h"
#import "VLCTrackSelectorHeaderView.h"
#import "VLCTrackSelectorTableViewCell.h"

#import "UIDevice+VLC.h"

#define TRACK_SELECTOR_TABLEVIEW_CELL @"track selector table view cell"
#define TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER @"track selector table view section header"

@interface VLCTrackSelectorView() <UITableViewDataSource, UITableViewDelegate>
{
    UITableView *_trackSelectorTableView;
    NSLayoutConstraint *_heightConstraint;
    VLCPlaybackService *_playbackService;
}
@end

@implementation VLCTrackSelectorView

- (instancetype)initWithFrame:(CGRect)frame
              playbackService:(VLCPlaybackService *)playbackService;
{
    self = [super initWithFrame:frame];
    if (self) {
        _playbackService = playbackService;
        _trackSelectorTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _trackSelectorTableView.delegate = self;
        _trackSelectorTableView.dataSource = self;
        _trackSelectorTableView.separatorColor = [UIColor clearColor];
        _trackSelectorTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _trackSelectorTableView.rowHeight = 44.;
        _trackSelectorTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _trackSelectorTableView.sectionHeaderHeight = 28.;
        [_trackSelectorTableView registerClass:[VLCTrackSelectorTableViewCell class] forCellReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL];
        [_trackSelectorTableView registerClass:[VLCTrackSelectorHeaderView class] forHeaderFooterViewReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];
        _trackSelectorTableView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_trackSelectorTableView];
        [self setupConstraints];
        [self configureForDeviceCategory];
    }
    return self;
}

- (void)configureForDeviceCategory
{
    _trackSelectorTableView.opaque = NO;
    _trackSelectorTableView.backgroundColor = [UIColor clearColor];
    _trackSelectorTableView.allowsMultipleSelection = YES;
}

- (void)layoutSubviews
{
    CGFloat height = _trackSelectorTableView.contentSize.height;
    _heightConstraint.constant = height;
    [super layoutSubviews];
}

- (void)setupConstraints
{
    _heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44];
    _heightConstraint.priority = UILayoutPriorityDefaultHigh;
    NSArray *constraints = @[
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1 constant:0],
                             [NSLayoutConstraint constraintWithItem:_trackSelectorTableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1 constant:0],
                             _heightConstraint,
                             ];
    [NSLayoutConstraint activateConstraints:constraints];
}
#pragma mark - track selector table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sections = 0;

    if (_switchingTracksNotChapters) {
        if([_playbackService numberOfAudioTracks] > 2)
            sections++;

        if ([_playbackService numberOfVideoSubtitlesIndexes] > 1)
            sections++;
    } else {
        if ([_playbackService numberOfTitles] > 1)
            sections++;

        if ([_playbackService numberOfChaptersForCurrentTitle] > 1)
            sections++;
    }

    return sections;
}

- (void)updateView
{
    [_trackSelectorTableView reloadData];
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UITableViewHeaderFooterView *view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];

    if (!view) {
        view = [[VLCTrackSelectorHeaderView alloc] initWithReuseIdentifier:TRACK_SELECTOR_TABLEVIEW_SECTIONHEADER];
    }
    return view;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_switchingTracksNotChapters) {
        if ([_playbackService numberOfAudioTracks] > 2 && section == 0)
            return NSLocalizedString(@"CHOOSE_AUDIO_TRACK", nil);

        if ([_playbackService numberOfVideoSubtitlesIndexes] > 1)
            return NSLocalizedString(@"CHOOSE_SUBTITLE_TRACK", nil);
    } else {
        if ([_playbackService numberOfTitles] > 1 && section == 0)
            return NSLocalizedString(@"CHOOSE_TITLE", nil);

        if ([_playbackService numberOfChaptersForCurrentTitle] > 1)
            return NSLocalizedString(@"CHOOSE_CHAPTER", nil);
    }

    return @"unknown track type";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VLCTrackSelectorTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TRACK_SELECTOR_TABLEVIEW_CELL forIndexPath:indexPath];

    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;

    if (_switchingTracksNotChapters) {
        NSString *trackName;
        if ([_playbackService numberOfAudioTracks] > 2 && section == 0) {
            if ([_playbackService indexOfCurrentAudioTrack] == row) {
                [cell setShowsCurrentTrack];
            }

            trackName = [_playbackService audioTrackNameAtIndex:row];
        } else {
            if ([_playbackService indexOfCurrentSubtitleTrack] == row) {
                [cell setShowsCurrentTrack];
            }

            trackName = [_playbackService videoSubtitleNameAtIndex:row];
        }

        if ([trackName isEqualToString:@"Disable"]) {
            cell.textLabel.text = NSLocalizedString(@"DISABLE_LABEL", nil);
        } else {
            cell.textLabel.text = trackName;
        }
    } else {
        if ([_playbackService numberOfTitles] > 1 && section == 0) {

            NSDictionary *description = [_playbackService titleDescriptionsDictAtIndex:row];
            if(description != nil) {
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCTitleDescriptionName], [[VLCTime timeWithNumber:description[VLCTitleDescriptionDuration]] stringValue]];
            }

            if (row == [_playbackService indexOfCurrentTitle]) {
                [cell setShowsCurrentTrack];
            }
        } else {
            NSDictionary *description = [_playbackService chapterDescriptionsDictAtIndex:row];
            if (description != nil)
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", description[VLCChapterDescriptionName], [[VLCTime timeWithNumber:description[VLCChapterDescriptionDuration]] stringValue]];
        }

        if (row == [_playbackService indexOfCurrentChapter])
            [cell setShowsCurrentTrack];
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_switchingTracksNotChapters) {
        if ([_playbackService numberOfAudioTracks] > 2 && section == 0)
            return [_playbackService numberOfAudioTracks];

        return [_playbackService numberOfVideoSubtitlesIndexes];
    } else {
        if ([_playbackService numberOfTitles] > 1 && section == 0)
            return [_playbackService numberOfTitles];
        else
            return [_playbackService numberOfChaptersForCurrentTitle];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger index = indexPath.row;

    if (_switchingTracksNotChapters) {
        if ([_playbackService numberOfAudioTracks] > 2 && indexPath.section == 0) {
            [_playbackService selectAudioTrackAtIndex:index];

        } else if (index <= [_playbackService numberOfVideoSubtitlesIndexes]) {
            [_playbackService selectVideoSubtitleAtIndex:index];
        }
    } else {
        if ([_playbackService numberOfTitles] > 1 && indexPath.section == 0)
            [_playbackService selectTitleAtIndex:index];
        else
            [_playbackService selectChapterAtIndex:index];
    }

    self.alpha = 1.0f;
    void (^animationBlock)(void) = ^() {
        self.alpha =  0.0f;;
    };

    NSTimeInterval animationDuration = .3;
    [UIView animateWithDuration:animationDuration animations:animationBlock completion:_completionHandler];
}
@end
