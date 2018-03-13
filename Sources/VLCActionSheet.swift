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

// TODO: - custom layout x
//       - custom cell
//       - datasource
//       - gestures (tap away, select renderer)

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
}

class VLCActionSheetCell: UICollectionViewCell {

    let icon: UIImageView = {
        let icon = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))

        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()

    let name: UILabel = {
        let name = UILabel()

        name.textColor = UIColor.orange
        name.translatesAutoresizingMaskIntoConstraints = false
        return name
    }()

    let stackView: UIStackView = {
        let stackView = UIStackView()

        stackView.spacing = 15.0
        stackView.axis = .vertical
        stackView.alignment = .leading
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

        icon.heightAnchor.constraint(equalTo: icon.widthAnchor)

        stackView.topAnchor.constraint(equalTo: topAnchor)
        stackView.centerXAnchor.constraint(equalTo: centerXAnchor)

        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(name)
    }
}

open class VLCActionSheet: UIViewController {

    let cellIdentifier = "VLCActionSheetCell"

    // background black layer
    lazy var backgroundView: UIView = {
        let backgroundView = UIView()

        backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
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
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(VLCActionSheetCell.self, forCellWithReuseIdentifier: cellIdentifier)
        return collectionView
    }()

    // MARK: UIViewController

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(backgroundView)
        view.addSubview(collectionView)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        backgroundView.frame = view.bounds
    }

}

// MARK: UICollectionViewDelegate
extension VLCActionSheet: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
}

// MARK: UICollectionViewDataSource
extension VLCActionSheet: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! VLCActionSheetCell

        return cell
    }
}
