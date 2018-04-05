/*****************************************************************************
 * MediaViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <nitz.carola # gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation

@objc public protocol VLCMediaViewControllerDelegate: class {
    func mediaViewControllerDidSelectMediaObject(_ mediaViewController: VLCMediaViewController, mediaObject: NSManagedObject)
    func mediaViewControllerDidSelectSort(_ mediaViewController: VLCMediaViewController)
}

public class VLCMediaViewController: UICollectionViewController, UISearchResultsUpdating, UISearchControllerDelegate {
    private var services: Services
    private var mediaDatasourceAndDelegate: MediaDataSourceAndDelegate?
    private var searchController: UISearchController?
    private let searchDataSource = VLCLibrarySearchDisplayDataSource()

    private lazy var renderersBarButtonItem: UIBarButtonItem = {
        let renderersBarButtonItem = UIBarButtonItem(image: UIImage(named: "renderer"),
                                                     style: .plain,
                                                     target: self,
                                                     action: #selector(displayRenderers))
        return renderersBarButtonItem
    }()

    public weak var delegate: VLCMediaViewControllerDelegate?

    @available(iOS 11.0, *)
    lazy var dragAndDropManager: VLCDragAndDropManager = {
        let dragAndDropManager = VLCDragAndDropManager()
        dragAndDropManager.delegate = services.mediaDataSource
        return dragAndDropManager
    }()

    public convenience init(services: Services) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.services = services
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .VLCThemeDidChangeNotification, object: nil)
    }

    public override init(collectionViewLayout layout: UICollectionViewLayout) {
        self.services = Services()
        super.init(collectionViewLayout: layout)
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupSearchController()
        setupNavigationBar()
        setupRendererDiscovererManager()
        _ = (MLMediaLibrary.sharedMediaLibrary() as! MLMediaLibrary).libraryDidAppear()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        VLCRendererDiscovererManager.sharedInstance.start()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func themeDidChange() {
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
    }

    func setupCollectionView() {
        mediaDatasourceAndDelegate = MediaDataSourceAndDelegate(services: services)
        mediaDatasourceAndDelegate?.delegate = self
        let playlistnib = UINib(nibName: "VLCPlaylistCollectionViewCell", bundle:nil)
        collectionView?.register(playlistnib, forCellWithReuseIdentifier: VLCPlaylistCollectionViewCell.cellIdentifier())
        collectionView?.backgroundColor = PresentationTheme.current.colors.background
        collectionView?.alwaysBounceVertical = true
        collectionView?.dataSource = mediaDatasourceAndDelegate
        collectionView?.delegate = mediaDatasourceAndDelegate
        if #available(iOS 11.0, *) {
            collectionView?.dragDelegate = dragAndDropManager
            collectionView?.dropDelegate = dragAndDropManager
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        services.mediaDataSource.updateContents(forSelection: nil)
        services.mediaDataSource.addAllFolders()
        services.mediaDataSource.addRemainingFiles()
        collectionView?.reloadData()

    }
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.delegate = self
        if let textfield = searchController?.searchBar.value(forKey: "searchField") as? UITextField {
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 10
                backgroundview.clipsToBounds = true
            }
        }
        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController?.searchBar
            searchController?.hidesNavigationBarDuringPresentation = false
        }
    }

    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Sort", comment: ""), style: .plain, target: self, action: #selector(sort))
    }

    // MARK: Renderer
    private func setupRendererDiscovererManager() {
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self,
                                  selector: #selector(handleRendererNotification(notification:)),
                                  name: .rendererDiscovererItemAdded,
                                  object: nil)
        defaultCenter.addObserver(self,
                                  selector: #selector(handleRendererNotification(notification:)),
                                  name: .rendererDiscovererItemRemoved,
                                  object: nil)
    }

    @objc private func handleRendererNotification(notification: Notification) {
        print("notification received |ω°•) with \(String(describing: notification.object))")

        guard let rendererItem = notification.object as? VLCRendererItem else {
            print("Something is wrong with the notification object!)")
            return
        }

        switch notification.name {
        case .rendererDiscovererItemAdded:
            print("notification: item added")
            // Add renderers button to the navigation bar on the first added notification
            if (navigationItem.rightBarButtonItem != renderersBarButtonItem) {
                navigationItem.rightBarButtonItem = renderersBarButtonItem
            }

        case .rendererDiscovererItemRemoved:
            if (VLCPlaybackController.sharedInstance().renderer == rendererItem) {
                // Selected renderer has been removed
                print("the selected renderer is gone!")
                VLCPlaybackController.sharedInstance().renderer = nil
            }

            if (VLCRendererDiscovererManager.sharedInstance.getAllRenderers().count == 0) {
                // No more renderers found
                navigationItem.rightBarButtonItem = nil
            }
            print("notification: item removed")
        default:
            print("unknown notification")
        }
    }

    @objc func displayRenderers() {
        let sheet = VLCActionSheet()
        sheet.dataSource = self
        sheet.modalPresentationStyle = .custom
        sheet.addAction { (item) in
            let rendererItem = item as? VLCRendererItem

            if (VLCPlaybackController.sharedInstance().renderer != rendererItem) {
                VLCPlaybackController.sharedInstance().renderer = rendererItem
            } else {
                VLCPlaybackController.sharedInstance().renderer = nil
            }
        }
        present(sheet, animated: false, completion: nil)
    }

    @objc func sort() {
        delegate?.mediaViewControllerDidSelectSort(self)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    // MARK: - MediaDatasourceAndDelegate
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.mediaViewControllerDidSelectMediaObject(self, mediaObject:services.mediaDataSource.object(at: UInt(indexPath.row)))
    }

    // MARK: - Search
    public func updateSearchResults(for searchController: UISearchController) {
        searchDataSource.shouldReloadTable(forSearch: searchController.searchBar.text, searchableFiles: services.mediaDataSource.allObjects())
        collectionView?.reloadData()
    }

    public func didPresentSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = searchDataSource
    }

    public func didDismissSearchController(_ searchController: UISearchController) {
        collectionView?.dataSource = mediaDatasourceAndDelegate
    }
}

extension VLCMediaViewController: VLCActionSheetDataSource {
    func numberOfRows() -> Int {
        return VLCRendererDiscovererManager.sharedInstance.getAllRenderers().count
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any? {
        return VLCRendererDiscovererManager.sharedInstance.getAllRenderers()[indexPath.row]
    }
}
