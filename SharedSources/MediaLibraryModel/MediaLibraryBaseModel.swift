/*****************************************************************************
 * MediaLibraryBaseModel.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol MediaLibraryBaseModel {
//    associatedtype MLType where MLType: VLCMLObject
//
//    init(medialibrary: VLCMediaLibraryManager)
//
//    var files: [MLType] { get set }
//
//    var updateView: (() -> Void)? { get set }
//
//    var indicatorName: String { get }
//
//    func append(_ item: MLType)
//    func isIncluded(_ item: MLType)

    init(medialibrary: VLCMediaLibraryManager)

    var anyfiles: [VLCMLObject] { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: VLCMLObject)
    func isIncluded(_ item: VLCMLObject)
    func sort(by criteria: VLCMLSortingCriteria)
}



protocol MLBaseModel: MediaLibraryBaseModel {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: VLCMediaLibraryManager)

    var files: [MLType] { get set }

    var medialibrary: VLCMediaLibraryManager { get }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: MLType)
    func isIncluded(_ item: MLType)
    func sort(by criteria: VLCMLSortingCriteria)
}

extension MLBaseModel {
    var anyfiles: [VLCMLObject] {
        return files as [VLCMLObject]
    }

    func append(_ item: VLCMLObject) {
        fatalError()
    }

    func isIncluded(_ item: VLCMLObject) {
        fatalError()
    }

    func sort(by criteria: VLCMLSortingCriteria) {
        fatalError()
    }
}
