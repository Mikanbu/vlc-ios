/*****************************************************************************
 * VLCMediaLibraryManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright © 2018 VideoLAN. All rights reserved.
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCMediaLibraryManager: NSObject {

    private static let databaseName: String = "medialibrary.db"
    private var databasePath: String!
    private var thumbnailPath: String!

    private lazy var medialibrary: VLCMediaLibrary = {
        let medialibrary = VLCMediaLibrary()
        medialibrary.delegate = self
        medialibrary.deviceListerDelegate = self
        return medialibrary
    }()

    override init() {
        super.init()
        setupMediaLibrary()
    }

    // MARK: Private
    private func setupMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first,
            let dbPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
                preconditionFailure("VLCMediaLibraryManager: Unable to init medialibrary.")
        }

        medialibrary.setVerbosity(.info)

        databasePath = dbPath + "/" + VLCMediaLibraryManager.databaseName
        thumbnailPath = documentPath

        let medialibraryStatus = medialibrary.setupMediaLibrary(databasePath: databasePath,
                                                                thumbnailPath: thumbnailPath)

        switch medialibraryStatus {
        case .success:
            guard medialibrary.start() else {
                assertionFailure("VLCMediaLibraryManager: Medialibrary failed to start.")
                return
            }
            medialibrary.reload()
            medialibrary.discover(onEntryPoint: "file://" + documentPath)
            break
        case .alreadyInitialized:
            assertionFailure("VLCMediaLibraryManager: Medialibrary already initialized.")
            break
        case .failed:
            preconditionFailure("VLCMediaLibraryManager: Failed to setup medialibrary.")
            break
        case .dbReset:
            // should still start and discover but warn the user that the db has been wipped
            assertionFailure("VLCMediaLibraryManager: The database was resetted, please re-configure.")
            break
        }
    }

    // MARK: Internal

    /// Returns number of *ALL* files(audio and video) present in the medialibrary database
    func numberOfFiles() -> Int {
        var media = medialibrary.audioFiles(with: .filename, desc: false)

        media += medialibrary.videoFiles(with: .filename, desc: false)
        return media.count
    }


    /// Returns *ALL* file found for a specified VLCMLMediaType
    ///
    /// - Parameter type: Type of the media
    /// - Returns: Array of VLCMLMedia
    func media(ofType type: VLCMLMediaType) -> [VLCMLMedia] {
        return type == .video ? medialibrary.videoFiles(with: .filename, desc: false) : medialibrary.audioFiles(with: .filename, desc: false)
    }

    func addMedia(withMrl mrl: URL) {
        medialibrary.addMedia(withMrl: mrl)
    }
}

// MARK: MediaDataSource - Audio methods

extension VLCMediaLibraryManager {
    private func getAllAudio() {
//        foundAudio = medialibrary.media(ofType: .audio)
//        artistsFromAudio()
//        albumsFromAudio()
//        audioPlaylistsFromAudio()
//        genresFromAudio()
    }

    private func getArtists() {
//        let albumtracks = MLAlbumTrack.allTracks() as! [MLAlbumTrack]
//        let tracksWithArtist = albumtracks.filter { $0.artist != nil && $0.artist != "" }
//        artists = tracksWithArtist.map { $0.artist }
    }

    private func getAlbums() {
//        albums = MLAlbum.allAlbums() as! [MLAlbum]
    }

    private func getAudioPlaylists() {
//        let labels = MLLabel.allLabels() as! [MLLabel]
//        audioPlaylist = labels.filter {
//            let audioFiles = $0.files.filter {
//                if let file = $0 as? MLFile {
//                    return file.isSupportedAudioFile()
//                }
//                return false
//            }
//            return !audioFiles.isEmpty
//        }
    }

    private func genresFromAudio() {
//        let albumtracks = MLAlbumTrack.allTracks() as! [MLAlbumTrack]
//        let tracksWithArtist = albumtracks.filter { $0.genre != nil && $0.genre != "" }
//        genres = tracksWithArtist.map { $0.genre }
    }
}

// MARK: MediaDataSource - Video methods

extension VLCMediaLibraryManager {
    private func getAllVideos() {
//        foundVideos = medialibrary.media(ofType: .video)
//        moviesFromVideos()
//        episodesFromVideos()
        //        videoPlaylistsFromVideos()
    }

    private func getMovies() {
//        movies = foundVideos.filter { $0.subtype() == .movie }
    }

    private func getShowEpisodes() {
//        episodes = foundVideos.filter { $0.subtype() == .showEpisode }
    }

    private func getVideoPlaylists() {
//        let labels = MLLabel.allLabels() as! [MLLabel]
//        audioPlaylist = labels.filter {
//            let audioFiles = $0.files.filter {
//                if let file = $0 as? MLFile {
//                    return file.isShowEpisode() || file.isMovie() || file.isClip()
//                }
//                return false
//            }
//            return !audioFiles.isEmpty
//        }
    }
}

// MARK: VLCMediaLibraryDelegate
extension VLCMediaLibraryManager: VLCMediaLibraryDelegate {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAddMedia media: [VLCMLMedia]) {
        print("VLCMediaLibraryDelegate: Did add media: \(media), with count: \(media.count)")
        print("VLCMediaLibraryDelegate: video count: \(medialibrary.videoFiles(with: .default, desc: false).count)")
        print("VLCMediaLibraryDelegate: audio count: \(medialibrary.audioFiles(with: .default, desc: false).count)")
        NotificationCenter.default.post(name: .VLCAllVideosDidChangeNotification, object: media)
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didStartDiscovery entryPoint: String) {
        print("VLCMediaLibraryDelegate: Did start discovery")
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didCompleteDiscovery entryPoint: String) {
        print("VLCMediaLibraryDelegate: Did complete discovery")
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didProgressDiscovery entryPoint: String) {
        print("VLCMediaLibraryDelegate: Did progress discovery")
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, didUpdateParsingStatsWithPercent percent: UInt32) {
        print("VLCMediaLibraryDelegate: Did update parsing with percent: \(percent)")
    }
}

// MARK: VLCMLDeviceListerDelegate
extension VLCMediaLibraryManager: VLCMLDeviceListerDelegate {

    func medialibrary(_ medialibrary: VLCMediaLibrary, devicePluggedWithUUID uuid: String, withMountPoint mountPoint: String) -> Bool {
        print("onDevicePlugged: \(uuid), mountPoint: \(mountPoint)")
        return false
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, deviceUnPluggedWithUUID uuid: String) {
        print("onDeviceUnplugged: \(uuid)")
    }

    func medialibrary(_ medialibrary: VLCMediaLibrary, isDeviceKnownWithUUID uuid: String) -> Bool {
        print("is device known: \(uuid)")
        return false
    }
}
