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
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            preconditionFailure("VLCMediaLibraryManager: Unable to init medialibrary.")
        }

        medialibrary.setVerbosity(.info)

        // the paths of the database & thumbnail are for now setted to the documentDirectory
        databasePath = documentPath + "/" + VLCMediaLibraryManager.databaseName
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
            assertionFailure("VLCMediaLibraryManager: The database was resetted, please re-configure.")
            break
        }
    }

    // Returns an array of VLCMLMedia
//    private func media(for type: VLCMLMediaType, subtype: VLCMLMediaSubType = .unknown) -> [VLCMLMedia] {
//        switch type {
//        case .unknown:
//            break
//        case .audio:
//            break
//        case .video:
//            break
//        }
//        return []
//    }
//    private func getAllVideos() {
//        print(medialibrary.videoFiles(with: .default, desc: false))
//    }

    // MARK: Internal

    /// Returns number of *ALL* files(audio and video) present in the medialibrary database
    func numberOfFiles() -> Int {
        var media = medialibrary.audioFiles(with: .filename, desc: false)

        media += medialibrary.videoFiles(with: .filename, desc: false)
        return media.count
    }

    func addMedia(withMrl mrl: URL) {
        medialibrary.addMedia(withMrl: mrl)
    }
}

extension VLCMediaLibraryManager: VLCMediaLibraryDelegate {

}

extension VLCMediaLibraryManager: VLCMLDeviceListerDelegate {

}
