/*****************************************************************************
 * MediaCategory.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCMovieCategoryViewController: VLCMediaCategoryViewController<VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCShowEpisodeCategoryViewController: VLCMediaCategoryViewController<ShowEpisodeModel> {
    init(_ services: Services) {
        let model = ShowEpisodeModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCVideoPlaylistCategoryViewController: VLCMediaCategoryViewController<VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCTrackCategoryViewController: VLCMediaCategoryViewController<AudioModel> {
    init(_ services: Services) {
        let model = AudioModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCGenreCategoryViewController: VLCMediaCategoryViewController<GenreModel> {
    init(_ services: Services) {
        let model = GenreModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCArtistCategoryViewController: VLCMediaCategoryViewController<ArtistModel> {
    init(_ services: Services) {
        let model = ArtistModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCAlbumCategoryViewController: VLCMediaCategoryViewController<AlbumModel> {
    init(_ services: Services) {
        let model = AlbumModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}

class VLCAudioPlaylistCategoryViewController: VLCMediaCategoryViewController<VideoModel> {
    init(_ services: Services) {
        let model = VideoModel(medialibrary: services.medialibraryManager)
        super.init(services: services, category: model)
        category.updateView = { [weak self] in
            self?.reloadData()
        }
    }
}
