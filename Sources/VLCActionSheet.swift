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
//       - custom cell x
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
        icon.image = UIImage(named: "vlcCone")
        icon.backgroundColor = .magenta
        icon.translatesAutoresizingMaskIntoConstraints = false
        return icon
    }()

    let name: UILabel = {
        let name = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 40))

        name.text = "testy"
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
        stackView.addArrangedSubview(icon)
        stackView.addArrangedSubview(name)
        addSubview(stackView)

        icon.leadingAnchor.constraint(equalTo: stackView.leadingAnchor)
        icon.heightAnchor.constraint(equalTo: icon.widthAnchor)
        icon.trailingAnchor.constraint(equalTo: name.leadingAnchor, constant: 15)

        name.leadingAnchor.constraint(equalTo: icon.trailingAnchor)
        name.trailingAnchor.constraint(equalTo: stackView.trailingAnchor)
//        stackView.topAnchor.constraint(equalTo: topAnchor)
//        stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
//        stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor)
        stackView.heightAnchor.constraint(equalTo: heightAnchor)
    }
}

open class VLCActionSheet: UIViewController {

    private let cellIdentifier = "VLCActionSheetCell"
    private let cellHeight = 50
    // init in param dataset(renderer array)
    @objc open var data: Array<Any>!

    private var actions = [Any]()

    // background black layer
    lazy var backgroundView: UIView = {
        let backgroundView = UIView()

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
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .lightGray
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(VLCActionSheetCell.self, forCellWithReuseIdentifier: cellIdentifier)

        return collectionView
    }()

    @objc init(_ data: Array<Any>) {
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }

    // This cannot work without a passed collection of data
    public required init?(coder aDecoder: NSCoder) {
        fatalError("Oh noes, no NSCoding")
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    @objc private func removeActionSheet() {
        super.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func setupCollectionView() {
        let viewBounds = view.bounds
        collectionView.frame = CGRect(origin: CGPoint(x: viewBounds.origin.x, y: UIScreen.main.bounds.height),
                                      size: CGSize(width: viewBounds.size.width, height: viewBounds.size.height / 2))
//        collectionView.frame = view.bounds

        // Setup content inset for scrolling
        var contentHeight:CGFloat = 0.0

        for _ in 1...data.count {
            if (contentHeight < viewBounds.size.height / 2) {
                contentHeight += CGFloat(cellHeight)
            }
        }
        collectionView.frame.origin.y -= contentHeight
    }

    // MARK: UIViewController
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backgroundView)
        view.addSubview(collectionView)
        setupCollectionView()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        backgroundView.frame = view.bounds
    }
}

extension VLCActionSheet: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: CGFloat(cellHeight))
    }
}

// MARK: UICollectionViewDelegate
extension VLCActionSheet: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //call callback
        print("didSelect: \(indexPath)")
    }
}

// MARK: UICollectionViewDataSource
extension VLCActionSheet: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! VLCActionSheetCell
        cell.name.text = "(╯°□°）╯︵ ┻━┻"
        return cell
    }
}
