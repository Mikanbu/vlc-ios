/*****************************************************************************
 * VLCActionSheet.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import Foundation
import UIKit

// MARK: VLCRendererCollectionViewLayout
class VLCRendererCollectionViewLayout: UICollectionViewFlowLayout {

    override init() {
        super.init()
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupLayout()
    }

    private func setupLayout() {
        minimumLineSpacing = 1
        minimumInteritemSpacing = 0
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

// MARK: VLCActionSheetCell
class VLCActionSheetCell: UICollectionViewCell {

    static let identifier = "VLCActionSheetCell"

    let icon: UIImageView = {
        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        return icon
    }()

    let name: UILabel = {
        let name = UILabel()
        name.font = UIFont.systemFont(ofSize: 15)
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 15.0
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    private func setupViews() {
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(name)
        addSubview(stackView)

        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        NSLayoutConstraint.activate([
            icon.heightAnchor.constraint(equalToConstant: 25),
            icon.widthAnchor.constraint(equalTo: icon.heightAnchor),

            name.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            name.centerYAnchor.constraint(equalTo: stackView.centerYAnchor),

            stackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: 10),
            stackView.heightAnchor.constraint(equalTo: heightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}

// MARK: VLCActionSheetSectionHeader
class VLCActionSheetSectionHeader: UIView {

    static let identifier = "VLCActionSheetSectionHeader"

    let title: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 16)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .darkGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupSeparator() {
        addSubview(separator)
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.widthAnchor.constraint(equalTo: widthAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
            separator.topAnchor.constraint(equalTo: bottomAnchor)
            ])
    }

    private func setupView() {
        addSubview(title)
        NSLayoutConstraint.activate([
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            title.centerYAnchor.constraint(equalTo: centerYAnchor),
            title.centerXAnchor.constraint(equalTo: centerXAnchor),
            title.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}

@objc protocol VLCActionSheetDataSource: class {
    @objc func numberOfRows() -> Int
    @objc func itemAtIndexPath(_ indexPath: IndexPath) -> Any?
}

// MARK: VLCActionSheet
class VLCActionSheet: UIViewController {

    private let cellHeight: CGFloat = 50

    @objc weak var dataSource: VLCActionSheetDataSource?

    private var action: ((_ item: Any) -> Void)?

    // background black layer
    lazy var backgroundView: UIView = {
        let backgroundView = UIView()
        backgroundView.isHidden = true
        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.removeActionSheet)))
        return backgroundView
    }()

    lazy var collectionViewLayout: VLCRendererCollectionViewLayout = {
        let collectionViewLayout = VLCRendererCollectionViewLayout()
        return collectionViewLayout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: UIScreen.main.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(VLCActionSheetCell.self, forCellWithReuseIdentifier: VLCActionSheetCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.addTarget(self, action: #selector(self.removeActionSheet), for: .touchDown)
        cancelButton.backgroundColor = UIColor(red:1.00, green:0.59, blue:0.13, alpha:1.0)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        return cancelButton
    }()

    lazy var headerView: VLCActionSheetSectionHeader = {
        let headerView = VLCActionSheetSectionHeader()
        headerView.title.text = "Select a casting device"
        headerView.title.textColor = .white
        headerView.title.textAlignment = .center
        headerView.backgroundColor = UIColor(red:1.00, green:0.59, blue:0.13, alpha:1.0)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()

    lazy var bottomBackgroundView: UIView = {
        let bottomBackgroundView = UIView()
        bottomBackgroundView.backgroundColor = UIColor(red:1.00, green:0.59, blue:0.13, alpha:1.0)
        bottomBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        return bottomBackgroundView
    }()

    // Cache only this constraint to update the height on rotation
    lazy var lesserCollectionViewHeightConstraint: NSLayoutConstraint = {
        let lesserCollectionViewHeightConstraint = NSLayoutConstraint(item: collectionView,
                                                                      attribute: .height,
                                                                      relatedBy: .lessThanOrEqual,
                                                                      toItem: nil,
                                                                      attribute: .height,
                                                                      multiplier: 1,
                                                                      constant: view.bounds.height / 2)
        lesserCollectionViewHeightConstraint.priority = UILayoutPriority(rawValue: 1000)
        return lesserCollectionViewHeightConstraint
    }()

    lazy var bottomBackgroundViewHeightConstraint: NSLayoutConstraint = {
        let bottomBackgroundViewHeightConstraint = NSLayoutConstraint(item: bottomBackgroundView,
                                                                      attribute: .height,
                                                                      relatedBy: .equal,
                                                                      toItem: nil,
                                                                      attribute: .height,
                                                                      multiplier: 1,
                                                                      constant: cellHeight)
        return bottomBackgroundViewHeightConstraint
    }()

    // MARK: Private methods
    @objc private func removeActionSheet() {
        UIView.transition(with: backgroundView, duration: 0.01, options: .transitionCrossDissolve, animations: {
            [weak self] in
            self?.backgroundView.isHidden = true
            }, completion: { finished in
                super.presentingViewController?.dismiss(animated: true, completion: nil)
        })
    }

    private func setupCancelButtonConstraints() {
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cancelButton.heightAnchor.constraint(equalToConstant: cellHeight)
            ])
    }

    private func setuplHeaderViewConstraints() {
        NSLayoutConstraint.activate([
            headerView.bottomAnchor.constraint(equalTo: collectionView.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: cellHeight),
            headerView.widthAnchor.constraint(equalTo: view.widthAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            ])
    }

    private func setupCollectionViewConstraints() {
        guard let dataSource = dataSource else {
            print("VLCActionSheet: DataSource not setted correctly!")
            return
        }

        let greaterCollectionViewHeightConstraint = NSLayoutConstraint(item: collectionView,
                                                                       attribute: .height,
                                                                       relatedBy: .greaterThanOrEqual,
                                                                       toItem: nil,
                                                                       attribute: .height,
                                                                       multiplier: 1,
                                                                       constant: CGFloat(dataSource.numberOfRows()) * cellHeight)

        greaterCollectionViewHeightConstraint.priority = UILayoutPriority(rawValue: 999)

        NSLayoutConstraint.activate([
            greaterCollectionViewHeightConstraint,
            lesserCollectionViewHeightConstraint,
            collectionView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor),
            collectionView.widthAnchor.constraint(equalTo: view.widthAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            ])
    }

    private func setupBottomBackgroundView() {
        NSLayoutConstraint.activate([
            bottomBackgroundViewHeightConstraint,
            bottomBackgroundView.topAnchor.constraint(equalTo: cancelButton.topAnchor),
            bottomBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
    }

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        bottomBackgroundViewHeightConstraint.constant = cellHeight + view.safeAreaInsets.bottom
    }

    // MARK: UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(backgroundView)
        view.addSubview(collectionView)
        view.addSubview(headerView)
        view.addSubview(bottomBackgroundView)
        view.addSubview(cancelButton)

        backgroundView.frame = UIScreen.main.bounds

        setupCollectionViewConstraints()
        setupCancelButtonConstraints()
        setuplHeaderViewConstraints()
        setupBottomBackgroundView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.isHidden = true
        headerView.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // This hidden dance is to avoid a horrible glitch!
        collectionView.isHidden = false
        headerView.isHidden = false

        UIView.transition(with: backgroundView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            [weak self] in
            self?.backgroundView.isHidden = false
            }, completion: nil)

        let realCollectionViewFrame = collectionView.frame
        let realHeaderViewFrame = headerView.frame

        collectionView.frame.origin.y += collectionView.frame.origin.y
        headerView.frame.origin.y += collectionView.frame.origin.y

        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            [weak self] in
            self?.collectionView.frame = realCollectionViewFrame
            self?.headerView.frame = realHeaderViewFrame
            }, completion: nil)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.lesserCollectionViewHeightConstraint.constant = size.height / 2
        })
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    @objc func addAction(closure action: @escaping (_ item: Any) -> Void) {
        self.action = action
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension VLCActionSheet: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
}

// MARK: UICollectionViewDelegate
extension VLCActionSheet: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let renderer = dataSource?.itemAtIndexPath(indexPath) {
            action?(renderer)
            removeActionSheet()
        }
    }
}

// MARK: UICollectionViewDataSource
extension VLCActionSheet: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let dataSource = dataSource {
            return dataSource.numberOfRows()
        }
        return 0
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VLCActionSheetCell.identifier, for: indexPath) as! VLCActionSheetCell

        if let renderer = dataSource?.itemAtIndexPath(indexPath) as? VLCRendererItem {
            cell.name.text = renderer.name
            cell.icon.image = UIImage(named: "rendererBlack")
        } else {
            cell.name.text = "(╯°□°）╯︵ ┻━┻"
        }
        return cell
    }
}
