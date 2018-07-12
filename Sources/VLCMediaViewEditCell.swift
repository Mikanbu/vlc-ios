/*****************************************************************************
 * VLCMediaViewEditCell.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

// https://www.figma.com/file/ByhPBHr4gTmUwo4bsVcanWIN/VLC180510?node-id=0%3A2

class VLCMediaViewEditCell: UICollectionViewCell {

    static let identifier = String(describing: VLCMediaViewEditCell.self)

    let stateView: UIView = {
        // 20 x 20 circle
        // maybe a struct to have a state bool?
        let stateView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        stateView.layer.cornerRadius = stateView.frame.width / 2
        stateView.clipsToBounds = true
        stateView.translatesAutoresizingMaskIntoConstraints = false
        stateView.backgroundColor = .green
        return stateView
    }()

    let thumbnail: UIImageView = {
        // 56 x 56 rounded corner ~ 2 - 3
        let thumbnail = UIImageView()
        thumbnail.translatesAutoresizingMaskIntoConstraints = false
        thumbnail.contentMode = .scaleAspectFit
        thumbnail.clipsToBounds = true
        thumbnail.layer.cornerRadius = 3
        return thumbnail
    }()

    let title: UILabel = {
        let title = UILabel()
        title.textColor = PresentationTheme.current.colors.cellTextColor
        title.font = UIFont.systemFont(ofSize: 17)
        title.translatesAutoresizingMaskIntoConstraints = false
        return title
    }()

    let subInfo: UILabel = {
        let subInfo = UILabel()
//        subInfo.textColor = PresentationTheme.current.colors.cellTextColor
        subInfo.font = UIFont.systemFont(ofSize: 13)
        subInfo.translatesAutoresizingMaskIntoConstraints = false
        return subInfo
    }()

    let size: UILabel = {
        let size = UILabel()
//        size.textColor = PresentationTheme.current.colors.cellTextColor
        size.font = UIFont.systemFont(ofSize: 11)
        size.translatesAutoresizingMaskIntoConstraints = false
        return size
    }()

    let mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.spacing = 20.0
        mainStackView.axis = .horizontal
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        return mainStackView
    }()

    let mediaInfoStackView: UIStackView = {
        let mediaInfoStackView = UIStackView()
        mediaInfoStackView.spacing = 5.0
        mediaInfoStackView.axis = .vertical
        mediaInfoStackView.alignment = .leading
        mediaInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        return mediaInfoStackView
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

        mediaInfoStackView.addArrangedSubview(title)
        mediaInfoStackView.addArrangedSubview(subInfo)
        mediaInfoStackView.addArrangedSubview(size)

        mainStackView.addArrangedSubview(stateView)
        mainStackView.addArrangedSubview(thumbnail)
        mainStackView.addArrangedSubview(mediaInfoStackView)

        addSubview(mainStackView)

        var guide: LayoutAnchorContainer = self

        if #available(iOS 11.0, *) {
            guide = safeAreaLayoutGuide
        }
        NSLayoutConstraint.activate([
            stateView.heightAnchor.constraint(equalToConstant: 20),
            stateView.widthAnchor.constraint(equalTo: stateView.heightAnchor),

            thumbnail.heightAnchor.constraint(equalToConstant: 56),
            thumbnail.widthAnchor.constraint(equalTo: thumbnail.heightAnchor),

            mainStackView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            mainStackView.heightAnchor.constraint(equalTo: heightAnchor),
            mainStackView.topAnchor.constraint(equalTo: topAnchor)
            ])
    }
}
