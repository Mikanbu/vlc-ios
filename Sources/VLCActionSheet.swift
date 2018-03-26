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

    let separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = .darkGray
        separator.translatesAutoresizingMaskIntoConstraints = false
        return separator
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
        addSubview(separator)

        separator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separator.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        separator.topAnchor.constraint(equalTo: stackView.bottomAnchor).isActive = true

        // StackView
        icon.heightAnchor.constraint(equalToConstant: 25).isActive = true
        icon.widthAnchor.constraint(equalTo: icon.heightAnchor).isActive = true

        name.trailingAnchor.constraint(equalTo: stackView.trailingAnchor).isActive = true
        name.centerYAnchor.constraint(equalTo: stackView.centerYAnchor).isActive = true

        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 10).isActive = true
        stackView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
    }
}

open class VLCActionSheet: UIViewController {

    private let cellIdentifier = "VLCActionSheetCell"
    private let cellHeight: CGFloat = 50

    @objc var data: Array<Any>!

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
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(VLCActionSheetCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    lazy var cancelButton: UIButton = {
        let cancelButton = UIButton()
        cancelButton.titleLabel?.text = "Cancel"
        cancelButton.addTarget(self, action: #selector(self.removeActionSheet), for: .touchDown)
        cancelButton.backgroundColor = .orange
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        return cancelButton
    }()

    // MARK: Initializer
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

    // MARK: Private methods
    @objc private func removeActionSheet() {
        UIView.transition(with: backgroundView, duration: 0.01, options: .transitionCrossDissolve, animations: {
            self.backgroundView.isHidden = true
        }, completion: { finished in
            super.presentingViewController?.dismiss(animated: true, completion: nil)
        })
    }

    private func setupCancelButtonConstraints() {
        cancelButton.topAnchor.constraint(equalTo: collectionView.bottomAnchor).isActive = true
        cancelButton.heightAnchor.constraint(equalToConstant: cellHeight).isActive = true
        cancelButton.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    private func setupCollectionViewConstraints() {
        let lesserHeightConstraint = NSLayoutConstraint(item: collectionView,
                                                  attribute: NSLayoutAttribute.height,
                                                  relatedBy: NSLayoutRelation.lessThanOrEqual,
                                                  toItem: nil,
                                                  attribute: NSLayoutAttribute.height,
                                                  multiplier: 1,
                                                  constant: view.bounds.height / 2)

        lesserHeightConstraint.priority = UILayoutPriority(rawValue: 1000)
        lesserHeightConstraint.isActive = true

        let greaterHeightConstraint = NSLayoutConstraint(item: collectionView,
                                                        attribute: NSLayoutAttribute.height,
                                                        relatedBy: NSLayoutRelation.greaterThanOrEqual,
                                                        toItem: nil,
                                                        attribute: NSLayoutAttribute.height,
                                                        multiplier: 1,
                                                        constant: CGFloat(data.count) * cellHeight)

        greaterHeightConstraint.priority = UILayoutPriority(rawValue: 999)
        greaterHeightConstraint.isActive = true

        collectionView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor).isActive = true
        collectionView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    }

    // MARK: UIViewController
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(backgroundView)
        view.addSubview(collectionView)
        view.addSubview(cancelButton)

        backgroundView.frame = UIScreen.main.bounds

        setupCollectionViewConstraints()
        setupCancelButtonConstraints()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UIView.transition(with: backgroundView, duration: 0.2, options: .transitionCrossDissolve, animations: {
            self.backgroundView.isHidden = false
        }, completion: nil)

        let realFrame = collectionView.frame

        collectionView.frame.origin.y += collectionView.frame.origin.y
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.collectionView.frame = realFrame
        }, completion: nil)
    }

    @objc func addAction(closure action: @escaping (_ item: Any) -> Void) {
        self.action = action
    }
}

extension VLCActionSheet: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: cellHeight)
    }
}

// MARK: UICollectionViewDelegate
extension VLCActionSheet: UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        action?(data[indexPath.row])
        removeActionSheet()
    }
}

// MARK: UICollectionViewDataSource
extension VLCActionSheet: UICollectionViewDataSource {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! VLCActionSheetCell

        if let renderer = data[indexPath.row] as? VLCRendererItem {
            cell.name.text = renderer.name
            cell.icon.image = UIImage(named: "rendererBlack")
        } else {
            cell.name.text = "(╯°□°）╯︵ ┻━┻"
        }
        return cell
    }
}
