/*****************************************************************************
 * GenreModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class GenreModel: MLBaseModel {
    typealias MLType = VLCMLGenre

    var updateView: (() -> Void)?

    var files = [VLCMLGenre]()

    var medialibrary: VLCMediaLibraryManager

    var indicatorName: String = NSLocalizedString("GENRE", comment: "")

    required init(medialibrary: VLCMediaLibraryManager) {
        self.medialibrary = medialibrary
        medialibrary.addObserver(self)
        files = medialibrary.genre()
    }

    func append(_ item: VLCMLGenre) {
        files.append(item)
    }
}

extension GenreModel: MediaLibraryObserver {
    func medialibrary(_ medialibrary: VLCMediaLibraryManager, didAddGenres genres: [VLCMLGenre]) {
        print("GenreModel: didAddGenre: \(genres.count)")
        genres.forEach({ append($0) })
        updateView?()
    }
}
