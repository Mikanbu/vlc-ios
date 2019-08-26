/*****************************************************************************
 * DragAndDropController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2019 VideoLAN. All rights reserved.
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import MobileCoreServices
import UIKit

@available(iOS 11.0, *)
struct DropError: Error {
    enum ErrorKind {
        case moveFileToDocuments
        case loadFileRepresentationFailed
    }

    let kind: ErrorKind
}

@available(iOS 11.0, *)
protocol DragAndDropManagerDelegate: NSObjectProtocol {
    func dragAndDropManagerRequestsFile(manager: NSObject, atIndexPath indexPath: IndexPath) -> VLCMLObject
    func dragAndDropManagerInsertItem(manager: NSObject, item: VLCMLObject, atIndexPath indexPath: IndexPath)
    func dragAndDropManagerDeleteItem(manager: NSObject, atIndexPath indexPath: IndexPath)
    func dragAndDropManagerCurrentSelection(manager: NSObject) -> VLCMLObject
    func dragAndDropManagerRemoveFileFromFolder(manager: NSObject, file: VLCMLObject)
}

@available(iOS 11.0, *)
class DragAndDropController: NSObject {
    private let utiTypeIdentifiers: [String] = DragAndDropController.supportedTypeIdentifiers()

    private var mediaLibraryService: MediaLibraryService
    private var model: MediaLibraryBaseModel
    private var presentingVC: MediaCategoryViewController

    init(mediaLibraryService: MediaLibraryService,
         model: MediaLibraryBaseModel, presentingVC: MediaCategoryViewController) {
        self.mediaLibraryService = mediaLibraryService
        self.model = model
        self.presentingVC = presentingVC
        super.init()
    }

        /// Returns the supported type identifiers that VLC can process.
        /// It fetches the identifiers in LSItemContentTypes from all the CFBundleDocumentTypes in the info.plist.
        /// Video, Audio and Subtitle formats
        ///
        /// - Returns: Array of UTITypeIdentifiers
        private class func supportedTypeIdentifiers() -> [String] {
            var typeIdentifiers: [String] = []
            if let documents = Bundle.main.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]] {
                for item in documents {
                    if let value = item["LSItemContentTypes"] as? [String] {
                        typeIdentifiers.append(contentsOf: value)
                    }
                }
            }
            return typeIdentifiers
        }
}

// MARK: - Private helpers

@available(iOS 11.0, *)
private extension DragAndDropController {
    // creating dragItems for the file at indexpath
    private func dragItems(forIndexPath indexPath: IndexPath) -> [UIDragItem] {
        let mlObject = presentingVC.dragAndDropManagerRequestsFile(manager: self, atIndexPath: indexPath)
        if fileIsCollection(atIndexPath: indexPath) {
            return dragItemsforCollection(mlObject: mlObject)
        }
        return dragItem(fromFile: mlObject)

//        assert(false, "we can't generate a dragfile if the delegate can't return a file ")
//        return []
    }

    /// Iterates over the items of a collection to create dragitems.
    /// Since we're not storing collections as folders we have to provide single files
    ///
    /// - Parameter file: Can be of type MLAlbum, MLLabel or MLShow
    /// - Returns: An array of UIDragItems
    private func dragItemsforCollection(mlObject: VLCMLObject) -> [UIDragItem] {
        var dragItems = [UIDragItem]()
        var mlObjects = [VLCMLObject]()

        if let collection = mlObject as? MediaCollectionModel {
            mlObjects = collection.files() ?? []
        } else {
            assertionFailure("dragItemsforCollection: mlObject not a MediaCollectionModel")
        }

        for convertibleFile in mlObjects {
            if let media = convertibleFile as? VLCMLMedia, let item = dragItem(fromFile: media).first {
                dragItems.append(item)
            }
        }
        return dragItems
    }

    //Provides an item for other applications
    private func dragItem(fromFile file: Any) -> [UIDragItem] {
        guard let mlObject = mlMedia(from: file as AnyObject), let path = mlObject.mainFile()?.mrl else {
            assertionFailure("dragItem: Fail to create a dragItem without MRL.")
            return []
        }

        let data = try? Data(contentsOf: path, options: .mappedIfSafe)
        let itemProvider = NSItemProvider()
        itemProvider.suggestedName = path.lastPathComponent
        // maybe use UTTypeForFileURL
        if let identifiers = try? path.resourceValues(forKeys: [.typeIdentifierKey]),
            let identifier = identifiers.typeIdentifier {
            // here we can show progress
            itemProvider.registerDataRepresentation(forTypeIdentifier: identifier,
                                                    visibility: .all) {
                                                        completion -> Progress? in
                                                        completion(data, nil)
                                                        return nil
            }
            let dragitem = UIDragItem(itemProvider: itemProvider)
            dragitem.localObject = mlObject
            return [dragitem]
        }
        assertionFailure("dragItem: Fail to provide a typeIdentifier.")
        return []
    }

    // FIXME: Perhaps delete method
    private func mlMedia(from file: AnyObject) -> VLCMLMedia? {
//        if let episode = file as? VLCMLShowEpisode, let convertedfile = episode.files.first as? VLCMLMedia {
//            return convertedfile
//        }
//
//        if let track = file as? VLCMLAlbumTrack, let convertedfile = track.files.first as? VLCMLMedia {
//            return convertedfile
//        }

        if let convertedfile = file as? VLCMLMedia {
            return convertedfile
        }
        return nil
    }

    // Add to playlist VLCMLPlaylist-> PlaylistModel?
    private func add(media: VLCMLMedia, toPlaylist playlistIndex: IndexPath) {
        let playlist = presentingVC.dragAndDropManagerRequestsFile(manager: self,
                                                                   atIndexPath: playlistIndex) as! VLCMLPlaylist
        // FIXME: Main thread async?
        DispatchQueue.main.async {
            playlist.appendMedia(media)
            //            _ = label.files.insert(file)
            //            file.labels = [label]
//            file.folderTrackNumber = NSNumber(integerLiteral: label.files.count - 1)
        }
    }

    /// try to create a file from the dropped item
    ///
    /// - Parameters:
    ///   - itemProvider: itemprovider which is used to load the files from
    ///   - completion: callback with the successfully created file or error if it failed
    private func createMedia(with itemProvider: NSItemProvider,
                             completion: @escaping ((VLCMLMedia?, Error?) -> Void)) {

        itemProvider.loadFileRepresentation(forTypeIdentifier: kUTTypeData as String) {
            [weak self] (url, error) in
            guard let strongSelf = self else { return }

            guard let url = url else {
                DispatchQueue.main.async {
                    completion(nil, DropError(kind: .loadFileRepresentationFailed))
                }
                return
            }
            // returns nil for local session but this should also not be called for a local session
            guard let destinationURL = strongSelf.moveMediaToDocuments(fromURL: url) else {
                DispatchQueue.main.async {
                    completion(nil, DropError(kind: .moveFileToDocuments))
                }
                return
            }
            DispatchQueue.global(qos: .background).async {
//                let sharedlib = MLMediaLibrary.sharedMediaLibrary() as? MLMediaLibrary
//                sharedlib?.addFilePaths([destinationURL.path])
//                if let file = MLFile.file(for: destinationURL).first as? MLFile {

                // FIXME: The destinationURL must already be valid
                if let media = self?.mediaLibraryService.fetchMedia(with: destinationURL) {
                    DispatchQueue.main.async {
                        // we dragged into a folder
                        if let playlist = strongSelf.presentingVC.dragAndDropManagerCurrentSelection(manager: strongSelf) as? VLCMLPlaylist {
                            // FIXME: Add to playlist?
                            playlist.appendMedia(media)
//                            file.labels = [selection]
                        }
                        completion(media, nil)
                    }
                }
            }
        }
    }

    private func moveMediaToDocuments(fromURL filepath: URL?) -> URL? {
        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let newDirectoryPath = searchPaths.first
        guard let directoryPath = newDirectoryPath, let url = filepath else {
            return nil
        }
        let destinationURL = URL(fileURLWithPath: "\(directoryPath)" + "/" + "\(url.lastPathComponent)")
        do {
            try FileManager.default.moveItem(at: url, to: destinationURL)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return destinationURL
    }
//}
//
//// MARK: - Private Shared Methods
//
//@available(iOS 11.0, *)
//private extension DragAndDropController {

    // Checks if the session has items conforming to typeidentifiers
    private func canHandleDropSession(session: UIDropSession) -> Bool {
        if session.localDragSession != nil {
            return true
        }
        return session.hasItemsConforming(toTypeIdentifiers: utiTypeIdentifiers)
    }

    /// Returns a drop operation type
    ///
    /// - Parameters:
    ///   - hasActiveDrag: State if the drag started within the app
    ///   - item: UIDragItem from session
    /// - Returns: UIDropOperation
    private func dropOperation(hasActiveDrag: Bool, firstSessionItem item: AnyObject?,
                               withDestinationIndexPath destinationIndexPath: IndexPath?) -> UIDropOperation {
//        let inAlbum = model.dragAndDropManagerCurrentSelection(manager: self) as? MLAlbum != nil
//        let inShow = model.dragAndDropManagerCurrentSelection(manager: self) as? MLShow != nil

        guard let destinationIndexPath = destinationIndexPath else {
            return .cancel
        }
        // you can move files into a folder or copy from anothr app into a folder
        if fileIsPlaylist(atIndexPath: destinationIndexPath) {
            // no dragging entire shows and albums into folders
            if let dragItem = item, let mlObject = dragItem.localObject as? VLCMLObject,
                mlObject is VLCMLAlbumTrack || mlObject is VLCMLShowEpisode {
                return .forbidden
            }
            return hasActiveDrag ? .move : .copy
        }

        // you can't reorder
//        if inFolder() {
//            return hasActiveDrag ? .forbidden : .copy
//        }

        // you can't reorder in or drag into an Album or Show
//        if inAlbum || inShow {
//            return .cancel
//        }

        // we're dragging a file out of a folder
//        if let dragItem = item, let mlFile = dragItem.localObject as? MLFile, !mlFile.labels.isEmpty {
//            return .copy
//        }

        // no reorder from another app into the top layer
        return hasActiveDrag ? .forbidden : .copy
    }

    /// Show an Alert when dropping failed
    ///
    /// - Parameters:
    ///   - error: the type of error that happend
    ///   - itemProvider: the itemProvider to retrieve the suggestedName
    private func handleError(error: DropError, itemProvider: NSItemProvider) {
        let message: String
        let filename = itemProvider.suggestedName ?? NSLocalizedString("THIS_FILE", comment: "")
        switch error.kind {
        case .loadFileRepresentationFailed:
            message = String(format: NSLocalizedString("NOT_SUPPORTED_FILETYPE", comment: ""), filename)
        case .moveFileToDocuments:
            message = String(format: NSLocalizedString("FILE_EXISTS", comment: ""), filename)
        }
        let alert = UIAlertController(title: NSLocalizedString("ERROR", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }

    private func fileIsPlaylist(atIndexPath indexPath: IndexPath) -> Bool {
        let mlObject = presentingVC.dragAndDropManagerRequestsFile(manager: self, atIndexPath: indexPath)
        return mlObject is VLCMLPlaylist
    }

    private func fileIsCollection(atIndexPath indexPath: IndexPath) -> Bool {
        let mlObject = presentingVC.dragAndDropManagerRequestsFile(manager: self, atIndexPath: indexPath)
        return mlObject is MediaCollectionModel
    }

//    private func inPlaylist() -> Bool {
//        inFolder()
//        return presentingVC.dragAndDropManagerCurrentSelection(manager: self) is VLCMLPlaylist
//    }

       private func moveItem(collectionView: UICollectionView,
                             item: UICollectionViewDropItem, toIndexPath destinationPath: IndexPath) {
        // make sure that this isn't inside a folder/playlist?
        //        , !mlObject.labels.isEmpty && !inFolder() {
        if let mlObject = item.dragItem.localObject as? VLCMLMedia {
                collectionView.performBatchUpdates({
                    collectionView.insertItems(at: [destinationPath])
                    presentingVC.dragAndDropManagerRemoveFileFromFolder(manager: self, file: mlObject)

                    presentingVC.dragAndDropManagerInsertItem(manager: self,
                                                              item: mlObject,
                                                              atIndexPath: destinationPath)
                }, completion: nil)
            }
        }

        private func addDragItem(collectionView: UICollectionView,
                                 dragItem item: UICollectionViewDropItem, toFolderAt index: IndexPath) {
            if let sourcepath = item.sourceIndexPath {
                // local file that just needs to be moved
                collectionView.performBatchUpdates({
                    if let mlObject = presentingVC.dragAndDropManagerRequestsFile(manager: self,
                                                                                  atIndexPath: sourcepath) as? VLCMLMedia {
                        collectionView.deleteItems(at: [sourcepath])
                        add(media: mlObject, toPlaylist: index)
                        presentingVC.dragAndDropManagerDeleteItem(manager: self, atIndexPath: sourcepath)
                    }
                }, completion: nil)
            } else {
                // file from other app
                createMedia(with itemProvider: item.dragItem.itemProvider) {
                    [weak self] file, error in
                    if let strongSelf = self, let file = file {
                        strongSelf.add(media: file, toPlaylist: index)
                    }
                }
            }
        }
}

// MARK: - UICollectionViewDragDelegate

@available(iOS 11.0, *)
extension DragAndDropController: UICollectionViewDragDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        return dragItems(forIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        itemsForAddingTo session: UIDragSession,
                        at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(forIndexPath: indexPath)
    }
}

// MARK: - UICollectionViewDropDelegate

@available(iOS 11.0, *)
extension DragAndDropController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return canHandleDropSession(session: session)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?)
        -> UICollectionViewDropProposal {
        let operation = dropOperation(hasActiveDrag: collectionView.hasActiveDrag, firstSessionItem: session.items.first, withDestinationIndexPath: destinationIndexPath)
        return UICollectionViewDropProposal(operation: operation, intent: .insertIntoDestinationIndexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {

        let section = collectionView.numberOfSections - 1
        let row = collectionView.numberOfItems(inSection: section)
        let destinationPath = coordinator.destinationIndexPath ?? IndexPath(row: row, section: section)

        for item in coordinator.items {
            if let sourceItem = item.dragItem.localObject, sourceItem is MediaCollectionModel {
                // We're not handling moving of Collection
                continue
            }
//            if fileIsFolder(atIndexPath: destinationPath) {
//                // handle dropping onto a folder
//                addDragItem(collectionView: collectionView, dragItem: item, toFolderAt: destinationPath)
//                continue
//            }
            if item.sourceIndexPath != nil {
                // element within VLC
                moveItem(collectionView: collectionView, item: item, toIndexPath: destinationPath)
                continue
            }

            // Element from another App
            let placeholder = UICollectionViewDropPlaceholder(insertionIndexPath: destinationPath,
                                                              reuseIdentifier: model.cellType.defaultReuseIdentifier)
            let placeholderContext = coordinator.drop(item.dragItem, to: placeholder)

            createMedia(with itemProvider: item.dragItem.itemProvider) {
                [weak self] file, error in

                guard let strongSelf = self else { return }

                if let file = file {
                    placeholderContext.commitInsertion() {
                        insertionIndexPath in
                        strongSelf.presentingVC.dragAndDropManagerInsertItem(manager: strongSelf,
                                                                             item: file,
                                                                             atIndexPath: insertionIndexPath)
                    }
                }
                if let error = error as? DropError {
                    strongSelf.handleError(error: error, itemProvider: item.dragItem.itemProvider)
                    placeholderContext.deletePlaceholder()
                }
            }
        }
    }
}

//, UICollectionViewDragDelegate, UITableViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate, UIDropInteractionDelegate {
//
//    // MARK: - TableView
//
//    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
//        return canHandleDropSession(session: session)
//    }
//
//    func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
//        return dragItems(forIndexPath: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
//        return dragItems(forIndexPath: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
//        let operation = dropOperation(hasActiveDrag: tableView.hasActiveDrag, firstSessionItem: session.items.first, withDestinationIndexPath: destinationIndexPath)
//        return UITableViewDropProposal(operation: operation, intent: .insertIntoDestinationIndexPath)
//    }
//
//    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
//        let section = tableView.numberOfSections - 1
//        let row = tableView.numberOfRows(inSection: section)
//        let destinationPath = coordinator.destinationIndexPath ?? IndexPath(row: row, section: section)
//
//        for item in coordinator.items {
//            let itemProvider = item.dragItem.itemProvider
//            // we're not gonna handle moving of folders
//            if let sourceItem = item.dragItem.localObject, fileIsCollection(file: sourceItem as AnyObject) {
//                continue
//            }
//
//            if fileIsFolder(atIndexPath: destinationPath) { // handle dropping onto a folder
//                addDragItem(tableView: tableView, dragItem: item, toFolderAt: destinationPath)
//                continue
//            }
//
//            if item.sourceIndexPath != nil { // element within VLC
//                moveItem(tableView: tableView, item: item, toIndexPath: destinationPath)
//                continue
//            }
//            // Element dragging from another App
//            let placeholder = UITableViewDropPlaceholder(insertionIndexPath: destinationPath, reuseIdentifier: VLCPlaylistTableViewCell.cellIdentifier(), rowHeight: VLCPlaylistTableViewCell.heightOfCell())
//            let placeholderContext = coordinator.drop(item.dragItem, to: placeholder)
//            createFileWith(itemProvider: itemProvider) {
//                [weak self] file, error in
//
//                guard let strongSelf = self else { return }
//
//                if let file = file {
//                    placeholderContext.commitInsertion() {
//                        insertionIndexPath in
//                        strongSelf.cateory.dragAndDropManagerInsertItem(manager: strongSelf, item: file, atIndexPath: insertionIndexPath)
//                    }
//                }
//                if let error = error as? DropError {
//                    strongSelf.handleError(error: error, itemProvider: item.dragItem.itemProvider)
//                    placeholderContext.deletePlaceholder()
//                }
//            }
//        }
//    }
//
//    private func inFolder() -> Bool {
//        return cateory.dragAndDropManagerCurrentSelection(manager: self) as? MLLabel != nil
//    }
//
//    private func moveItem(tableView: UITableView, item: UITableViewDropItem, toIndexPath destinationPath: IndexPath) {
//        if let mlFile = item.dragItem.localObject as? MLFile, !mlFile.labels.isEmpty && !inFolder() {
//            tableView.performBatchUpdates({
//                tableView.insertRows(at: [destinationPath], with: .automatic)
//                cateory.dragAndDropManagerInsertItem(manager: self, item: mlFile, atIndexPath: destinationPath)
//                cateory.dragAndDropManagerRemoveFileFromFolder(manager: self, file: mlFile)
//            }, completion: nil)
//        }
//    }
//
//    private func addDragItem(tableView: UITableView, dragItem item: UITableViewDropItem, toFolderAt index: IndexPath) {
//        if let sourcepath = item.sourceIndexPath { // local file that just needs to be moved
//            tableView.performBatchUpdates({
//                if let file = cateory.dragAndDropManagerRequestsFile(manager: self, atIndexPath: sourcepath) as? MLFile {
//                    tableView.deleteRows(at: [sourcepath], with: .automatic)
//                    addFile(file: file, toFolderAt: index)
//                    cateory.dragAndDropManagerDeleteItem(manager: self, atIndexPath: sourcepath)
//                }
//            }, completion: nil)
//            return
//        }
//        // file from other app
//        createFileWith(itemProvider: item.dragItem.itemProvider) {
//            [weak self] file, error in
//
//            if let strongSelf = self, let file = file {
//                strongSelf.addFile(file: file, toFolderAt: index)
//            }
//        }
//    }
//
