/*****************************************************************************
 * VideoModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

struct VideoModel: MediaLibraryBaseModel {
    typealias MLType = VLCMLMedia

    var files: [VLCMLMedia] = []

    var indicatorName: String = NSLocalizedString("MOVIES", comment: "")

    var notificaitonName: Notification.Name = .VLCVideosDidChangeNotification

    func isIncluded(_ item: VLCMLMedia) {
    }

    func append(_ item: VLCMLMedia) {
    }
}
