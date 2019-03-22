/*****************************************************************************
 * MediaViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

class VLCMediaViewController: VLCPagingViewController<VLCLabelCell> {
    var services: Services
    private var rendererButton: UIButton
    private lazy var searchButton = UIButton(frame: .zero)
    private var sortButton: UIBarButtonItem?

    init(services: Services) {
        self.services = services
        rendererButton = services.rendererDiscovererManager.setupRendererButton()
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {

        changeCurrentIndexProgressive = { (oldCell: VLCLabelCell?, newCell: VLCLabelCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) in
            guard changeCurrentIndex == true else { return }
            oldCell?.iconLabel.textColor = PresentationTheme.current.colors.cellDetailTextColor
            newCell?.iconLabel.textColor = PresentationTheme.current.colors.orangeUI
        }
        setupSearchButton()
        setupNavigationBar()
        super.viewDidLoad()
    }

    private func setupNavigationBar() {
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.rightBarButtonItems = [editButtonItem,
                                              UIBarButtonItem(customView: searchButton),
                                              UIBarButtonItem(customView: rendererButton)]
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("SORT", comment: ""),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(handleSort))
    }

    private func setupSearchButton() {
        searchButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        searchButton.tintColor = PresentationTheme.current.colors.orangeUI
        searchButton.setImage(UIImage(named: "search"), for: .normal)
        searchButton.addTarget(self, action: #selector(handleSearch), for: .touchUpInside)
        searchButton.accessibilityLabel = NSLocalizedString("BUTTON_SEARCH", comment: "")
        searchButton.accessibilityHint = NSLocalizedString("BUTTON_SEARCH_HINT", comment: "")
    }

    // MARK: - PagerTabStripDataSource

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        fatalError("this should only be used as subclass")
    }

    override func configure(cell: VLCLabelCell, for indicatorInfo: IndicatorInfo) {
        cell.iconLabel.text = indicatorInfo.title
    }

    override func updateIndicator(for viewController: PagerTabStripViewController, fromIndex: Int, toIndex: Int, withProgressPercentage progressPercentage: CGFloat, indexWasChanged: Bool) {
        super.updateIndicator(for: viewController, fromIndex: fromIndex, toIndex: toIndex, withProgressPercentage: progressPercentage, indexWasChanged: indexWasChanged)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return PresentationTheme.current.colors.statusBarStyle
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        scrollingEnabled(!editing)
        navigationItem.leftBarButtonItem = editing ? nil : sortButton
        viewControllers[currentIndex].setEditing(editing, animated: animated)
    }

    // Hack to send to the child vc the sort event
    override func handleSort() {
        viewControllers[currentIndex].handleSort()
    }

    override func handleSearch() {
        viewControllers[currentIndex].handleSearch()
    }
}

extension UIViewController {
    @objc func handleSort() {}

    @objc func handleSearch() {
        // The search isn't handled here because we need to have the current medialibrary context(model)
        //  this is handled inside VLCMediaCategoryViewController.
    }
}
