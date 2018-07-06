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

@objc protocol VLCMediaLibraryManagerDelegate {
    @objc optional func mediaAdded(_ media: VLCMLMedia)
}

class VLCMediaLibraryManager: NSObject {

    private static let databaseName: String = "medialibrary.db"
    private var databasePath: String!
    private var thumbnailPath: String!

    @objc weak var delegate: VLCMediaLibraryManagerDelegate?

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

// MARK: VLCMediaLibraryDelegate
extension VLCMediaLibraryManager: VLCMediaLibraryDelegate {
    func medialibrary(_ medialibrary: VLCMediaLibrary, didAddMedia media: [VLCMLMedia]) {
        print("VLCMediaLibraryDelegate: Did add media: \(media), with count: \(media.count)")
        print("VLCMediaLibraryDelegate: video count: \(medialibrary.videoFiles(with: .default, desc: false).count)")
        print("VLCMediaLibraryDelegate: audio count: \(medialibrary.audioFiles(with: .default, desc: false).count)")
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
