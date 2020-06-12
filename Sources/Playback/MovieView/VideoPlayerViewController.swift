/*****************************************************************************
 * VideoPlayerViewController.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

protocol VideoPlayerViewControllerDelegate: class {
    func videoPlayerViewControllerDidMinimize(_ videoPlayerViewController: VideoPlayerViewController)
    func videoPlayerViewControllerShouldBeDisplayed(_ videoPlayerViewController: VideoPlayerViewController) -> Bool
}

class VideoPlayerViewController: UIViewController {

    weak var delegate: VideoPlayerViewControllerDelegate?

    private var services: Services

    private var playbackService: PlaybackService = PlaybackService.sharedInstance()

    // MARK: - States

    private var isInterfaceLocked: Bool = false

    // MARK: - UI elements

    private lazy var mediaNavigationBar: MediaNavigationBar = {
        var mediaNavigationBar = MediaNavigationBar()
        mediaNavigationBar.delegate = self
        mediaNavigationBar.chromeCastButton.isHidden =
            self.playbackService.renderer == nil
        return mediaNavigationBar
    }()

    private lazy var mainControls: VideoPlayerMainControl = VideoPlayerMainControl()

    private lazy var subControls: VideoPlayerSubControl = {
        var subControls = VideoPlayerSubControl()
        subControls.delegate = self
        subControls.repeatMode = self.playbackService.repeatMode
        return subControls
    }()

    private lazy var scrubProgressBar: MediaScrubProgressBar = {
        var scrubProgressBar = MediaScrubProgressBar()
        scrubProgressBar.delegate = self
        return scrubProgressBar
    }()

    private lazy var moreOptionsActionSheet: MediaMoreOptionsActionSheet = {
        var moreOptionsActionSheet = MediaMoreOptionsActionSheet()
        moreOptionsActionSheet.moreOptionsDelegate = self
        return moreOptionsActionSheet
    }()

    private var videoOutputView: UIView = {
        var videoOutputView = UIView()
        videoOutputView.isUserInteractionEnabled = false

        if #available(iOS 11.0, *) {
            videoOutputView.accessibilityIgnoresInvertColors = true
        }
        videoOutputView.accessibilityIdentifier = "Video Player Title"
        videoOutputView.accessibilityLabel = NSLocalizedString("VO_VIDEOPLAYER_TITLE",
                                                               comment: "")
        videoOutputView.accessibilityHint = NSLocalizedString("VO_VIDEOPLAYER_DOUBLETAP",
                                                               comment: "")
        return videoOutputView
    }()

    // MARK: -
    init(services: Services) {
        self.services = services
        super.init(nibName: String(describing: VideoPlayerViewController.self),
                   bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
//        extendedLayoutIncludesOpaqueBars = true
//        edgesForExtendedLayout = .all
        navigationController?.navigationBar.isHidden = true
        setupViews()
        setupObservers()
    }
}

// MARK: - Private setups

private extension VideoPlayerViewController {
    private func setupViews() {
        view.addSubview(mediaNavigationBar)
        view.addSubview(mainControls)
        view.addSubview(subControls)
        view.addSubview(scrubProgressBar)
    }

    private func setupObservers() {
        let notificationCenter = NotificationCenter.default

        // External Screen
        notificationCenter.addObserver(self,
                                       selector: #selector(handleExternalScreenDidConnect),
                                       name: UIScreen.didConnectNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(handleExternalScreenDidDisconnect),
                                       name: UIScreen.didDisconnectNotification,
                                       object: nil)
        // UIApplication
        notificationCenter.addObserver(self,
                                       selector: #selector(handleAppBecameActive),
                                       name: UIApplication.didBecomeActiveNotification,
                                       object: nil)
        //
        notificationCenter.addObserver(self,
                                       selector: #selector(handlePlaybackDidStop),
                                       name: NSNotification.Name(rawValue: VLCPlaybackServicePlaybackDidStop),
                                       object: nil)
    }

    private func setupMediaNavigationBar() {

    }

    private func setupVideoPlayerMainControl() {

    }

    private func setupVideoPlayerSubControl() {

    }

    private func setupMediaScrubProgressionBar() {

    }
}
// MARK: - Observers

extension VideoPlayerViewController {
    @objc func handleExternalScreenDidConnect() {
//        [self showOnDisplay:_playingExternalView.displayView];
    }

    @objc func handleExternalScreenDidDisconnect() {
//        [self showOnDisplay:_movieView];
    }

    @objc func handleAppBecameActive() {
        guard let delegate = delegate else {
            preconditionFailure("VideoPlayerViewController: Delegate not assigned.")
        }

        if delegate.videoPlayerViewControllerShouldBeDisplayed(self) {
            playbackService.recoverDisplayedMetadata()
            if playbackService.videoOutputView != videoOutputView {
                playbackService.videoOutputView = videoOutputView
            }
        }
    }

    @objc func handlePlaybackDidStop() {
        guard let delegate = delegate else {
            preconditionFailure("VideoPlayerViewController: Delegate not assigned.")
        }

        delegate.videoPlayerViewControllerDidMinimize(self)
        // Reset interface to default icon when dismissed
        subControls.isInFullScreen = false
    }
}

// MARK: - Delegation

// MARK: - MediaNavigationBarDelegate

extension VideoPlayerViewController: MediaNavigationBarDelegate {
    func mediaNavigationBarDidTapMinimize(_ mediaNavigationBar: MediaNavigationBar) {
//        [_delegate movieViewControllerDidSelectMinimize:self];
    }

    func mediaNavigationBarDidLongPressMinimize(_ mediaNavigationBar: MediaNavigationBar) {
//        [self closePlayback:mediaNavigationBar.minimizePlaybackButton];
    }

    func mediaNavigationBarDidToggleChromeCast(_ mediaNavigationBar: MediaNavigationBar) {
        // TODO: Add current renderer functionality to chromeCast Button
//        NSAssert(0, @"didToggleChromeCast not implemented");
    }
}

// MARK: - VideoPlayerSubControlDelegate

extension VideoPlayerViewController: VideoPlayerSubControlDelegate {
    func didToggleFullScreen(_ optionsBar: VideoPlayerSubControl) {
        // FIXME: Is this what we want?
        playbackService.switchAspectRatio(false)
    }

    func didToggleRepeat(_ optionsBar: VideoPlayerSubControl) {
        playbackService.toggleRepeatMode()
        subControls.repeatMode = playbackService.repeatMode
    }

    func didSelectSubtitle(_ optionsBar: VideoPlayerSubControl) {

    }

    func didSelectMoreOptions(_ optionsBar: VideoPlayerSubControl) {
        present(moreOptionsActionSheet, animated: false) {
            [unowned self] in
            self.moreOptionsActionSheet.interfaceDisabled = self.isInterfaceLocked
        }
    }

    func didToggleInterfaceLock(_ optionsBar: VideoPlayerSubControl) {
        // toggleUILock
    }
}

// MARK: - MediaScrubProgressBarDelegate

extension VideoPlayerViewController: MediaScrubProgressBarDelegate {
    func mediaScrubProgressBarShouldResetIdleTimer() {
        // resetIdleTimer for animation
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension VideoPlayerViewController: MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        //
    }
}
