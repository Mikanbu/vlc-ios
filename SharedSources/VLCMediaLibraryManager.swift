/*****************************************************************************
 * VLCMediaLibraryManager.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Soomin Lee <bubu # mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCMediaLibraryManager: NSObject {

    private static let dbPath: String = "/medialibrary.db"

    lazy var medialibrary: VLCMediaLibrary = {
        let medialibrary = VLCMediaLibrary()
        medialibrary.delegate = self
        medialibrary.deviceListerDelegate = self
        return medialibrary
    }()

    override init() {
        super.init()
        setupMediaLibrary()
    }

    private func setupMediaLibrary() {
        guard let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            preconditionFailure("VLCMediaLibraryManager: Unable to init medialibrary.")
        }

        let medialibraryStatus = medialibrary.setupMediaLibrary(databasePath: documentPath + VLCMediaLibraryManager.dbPath,
                                                                thumbnailPath: documentPath)

        switch medialibraryStatus {
        case .success: break
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
}

extension VLCMediaLibraryManager: VLCMediaLibraryDelegate {

}

extension VLCMediaLibraryManager: VLCMLDeviceListerDelegate {

}
