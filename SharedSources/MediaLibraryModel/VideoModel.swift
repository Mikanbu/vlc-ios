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

class VideoModel: MediaLibraryBaseModel {
    typealias MLType = VLCMLMedia

    var files = [VLCMLMedia]()

    var view: MediaLibraryModelView?

    var indicatorName: String = NSLocalizedString("MOVIES", comment: "")

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

extension VideoModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddVideo video: [VLCMLMedia]) {
        print("VideoModel: didAddVideo: \(video.count)")
        video.forEach({ append($0) })
        view?.dataChanged()
    }
}
