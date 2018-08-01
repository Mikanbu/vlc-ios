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

protocol MediaLibraryModelView {
    func dataChanged()
}

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
}



protocol MLBaseModel: MediaLibraryBaseModel {
    associatedtype MLType where MLType: VLCMLObject

    init(medialibrary: VLCMediaLibraryManager)

    var files: [MLType] { get set }

    var updateView: (() -> Void)? { get set }

    var indicatorName: String { get }

    func append(_ item: MLType)
    func isIncluded(_ item: MLType)
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
}

//class AnyMediaLibraryModel<MediaType: VLCMLObject>: MediaLibraryBaseModel {
////where MediaType: VLCMLObject {
//    var files = [MediaType]()
//
//    var updateView: (() -> Void)?
//
//    var indicatorName = "AnyMediaLibraryModel"
//
//    private var _append: ((MediaType) -> Void)!
//    private var _isIncluded: ((MediaType) -> Void)!
//
//    required init(medialibrary: VLCMediaLibraryManager) { }
//
//    init<Type: MediaLibraryBaseModel>(model: Type)  where Type.MLType == MediaType {
////    init(model: MediaType) {
//        _append = model.append
//        _isIncluded = model.isIncluded
//    }
//
//    func append(_ item: MediaType) {
//        _append(item)
//    }
//
//    func isIncluded(_ item: MediaType) {
//        _isIncluded(item)
//    }
//}
