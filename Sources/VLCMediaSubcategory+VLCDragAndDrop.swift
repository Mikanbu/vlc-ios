/*****************************************************************************
 * MediaCategoryViewController+DragAndDrop.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@available(iOS 11.0, *)
extension MediaCategoryViewController: DragAndDropManagerDelegate {

    func dragAndDropManagerRequestsFile(manager: NSObject, atIndexPath indexPath: IndexPath) -> VLCMLObject {
        return model.anyfiles[indexPath.row]
    }

    func dragAndDropManagerInsertItem(manager: NSObject,
                                      item: VLCMLObject, atIndexPath indexPath: IndexPath) {
//        if item as? MLLabel != nil && indexPath.row < files.count {
//            files.remove(at: indexPath.row)
//        }

        if item as? VLCMLPlaylist != nil && indexPath.row < model.anyfiles.count {
            model.delete([model.anyfiles[indexPath.row]])
        }

        // TODO: handle insertion
        //files.insert(item, at: indexPath.row)
    }

    func dragAndDropManagerDeleteItem(manager: NSObject, atIndexPath indexPath: IndexPath) {
        //        model.remove(at: indexPath.row)
        model.delete([model.anyfiles[indexPath.row]])
    }

    func dragAndDropManagerCurrentSelection(manager: NSObject) -> VLCMLObject {

        //TODO: Handle playlists and Collections
        fatalError()
    }

    func dragAndDropManagerRemoveFileFromFolder(manager: NSObject, file: VLCMLObject) {
        //TODO: handle removing from playlists and Collections
        fatalError()
    }
}
