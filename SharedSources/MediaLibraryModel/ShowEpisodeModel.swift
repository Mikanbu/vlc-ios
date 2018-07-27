/*****************************************************************************
 * ShowEpisodeModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class ShowEpisodeModel: MediaLibraryBaseModel {
    typealias MLType = VLCMLMedia

    var files = [VLCMLMedia]()

    var indicatorName: String = NSLocalizedString("EPISODES", comment: "")

    var notificaitonName: Notification.Name = .VLCEpisodesDidChangeNotification

    required init(medialibrary: VLCMediaLibraryManager) {
        medialibrary.addObserver(self)
    }

    func isIncluded(_ item: VLCMLMedia) {
    }

    func append(_ item: VLCMLMedia) {
        // need to check more for duplicate and stuff
        files.append(item)
    }
}

extension ShowEpisodeModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddShowEpisode showEpisode: [VLCMLMedia]) {
        print("ShowEpisode: didAddShowEpisode: \(showEpisode.count)")
        showEpisode.forEach({ append($0) })
        // yikes
        NotificationCenter.default.post(name: notificaitonName, object: nil)
    }
}
