/*****************************************************************************
 * VideoPlayerViewController.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

@objc(VLCVideoPlayerViewControllerDelegate)
protocol VideoPlayerViewControllerDelegate: class {
    func videoPlayerViewControllerDidMinimize(_ videoPlayerViewController: VideoPlayerViewController)
    func videoPlayerViewControllerShouldBeDisplayed(_ videoPlayerViewController: VideoPlayerViewController) -> Bool
}

enum VideoPlayerSeekState {
    case `default`
    case forward
    case backward
}

struct VideoPlayerSeek {
    static let shortSeek: Int = 10

    struct Swipe {
        static let forward: Int = 10
        static let backward: Int = 10
    }
}

@objc(VLCVideoPlayerViewController)
class VideoPlayerViewController: UIViewController {
    @objc weak var delegate: VideoPlayerViewControllerDelegate?

    private var services: Services

    private var playerController: PlayerController

    private var playbackService: PlaybackService = PlaybackService.sharedInstance()

    // MARK: - Constants

    private let ZOOM_SENSITIVITY: CGFloat = 5

    private let screenPixelSize = CGSize(width: UIScreen.main.bounds.width,
                                         height: UIScreen.main.bounds.height)

    // MARK: - Private

    // MARK: - 360

    private var fov: CGFloat = 0
    private lazy var deviceMotion: DeviceMotion = {
        let deviceMotion = DeviceMotion()
        deviceMotion.delegate = self
        return deviceMotion
    }()

    // MARK: - Seek

    private var numberOfTapSeek: Int = 0
    private var previousSeekState: VideoPlayerSeekState = .default

    // MARK: - UI elements

    override var canBecomeFirstResponder: Bool {
        return true
    }

    private var idleTimer: Timer?

    // FIXME: -
//    override var prefersStatusBarHidden: Bool {
//        return _viewAppeared ? _controlsHidden : NO;
//    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private lazy var layoutGuide: UILayoutGuide = {
        var layoutGuide = view.layoutMarginsGuide

        if #available(iOS 11.0, *) {
            layoutGuide = view.safeAreaLayoutGuide
        }
        return layoutGuide
    }()

    private lazy var videoOutputViewLeadingConstraint: NSLayoutConstraint = {
        let videoOutputViewLeadingConstraint = videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        return videoOutputViewLeadingConstraint
    }()

    private lazy var videoOutputViewTrailingConstraint: NSLayoutConstraint = {
        let videoOutputViewTrailingConstraint = videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        return videoOutputViewTrailingConstraint
    }()

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

    // MARK: - VideoOutput

    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.alpha = 1
        shadowView.frame = UIScreen.main.bounds
        shadowView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        shadowView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return shadowView
    }()

    private var videoOutputView: UIView = {
        var videoOutputView = UIView()
        videoOutputView.backgroundColor = .black
        videoOutputView.isUserInteractionEnabled = false
        videoOutputView.translatesAutoresizingMaskIntoConstraints = false

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

    // FIXME: - Crash(inf loop) on init
    private lazy var externalVideoOutput: PlayingExternallyView = PlayingExternallyView()
//        = {
////        guard let externalVideoOutput = PlayingExternallyView() else {
//        guard let nib = Bundle.main.loadNibNamed("PlayingExternallyView",
//                                                 owner: self,
//                                                 options: nil)?.first as? PlayingExternallyView else {
//                                                    preconditionFailure("VideoPlayerViewController: Failed to load PlayingExternallyView.")
//        }
//        return  nib
//    }()

    // MARK: - Gestures

    private lazy var tapOnVideoRecognizer: UITapGestureRecognizer = {
        let tapOnVideoRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(handleTapOnVideo))
        return tapOnVideoRecognizer
    }()

    private lazy var playPauseRecognizer: UITapGestureRecognizer = {
        let playPauseRecognizer = UITapGestureRecognizer(target: self,
                                                          action: #selector(handlePlayPauseGesture))
        playPauseRecognizer.numberOfTouchesRequired = 2
        return playPauseRecognizer
    }()

    private lazy var pinchRecognizer: UIPinchGestureRecognizer = {
        let pinchRecognizer = UIPinchGestureRecognizer(target: self,
                                                       action: #selector(handlePinchGesture(recognizer:)))
        return pinchRecognizer
    }()

    private lazy var doubleTapRecognizer: UITapGestureRecognizer = {
        let doubleTapRecognizer = UITapGestureRecognizer(target: self,
                                                         action: #selector(handleDoubleTapGesture(recognizer:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        tapOnVideoRecognizer.require(toFail: doubleTapRecognizer)
        return doubleTapRecognizer
    }()

    // MARK: -

    @objc init(services: Services, playerController: PlayerController) {
        self.services = services
        self.playerController = playerController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -

    @available(iOS 11.0, *)
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        if UIDevice.current.userInterfaceIdiom != .phone {
            return
        }

        // safeAreaInsets can take some time to get set.
        // Once updated, check if we need to update the constraints for notches
        adaptVideoOutputToNotch()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playbackService.delegate = self
        playbackService.recoverPlaybackState()

        playerController.lockedOrientation = .portrait
        navigationController?.navigationBar.isHidden = true
        setControlsHidden(true, animated: false)

        // FIXME: Test userdefault
        // FIXME: Renderer discoverer

        if playbackService.isPlayingOnExternalScreen() {
            // FIXME: Handle error case
            changeVideoOuput(to: externalVideoOutput.displayView ?? videoOutputView)
        }

        if #available(iOS 11.0, *) {
            adaptVideoOutputToNotch()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        _viewAppeared = YES;
//        _playbackWillClose = NO;
//        setControlsHidden(true, animated: false)

        playbackService.recoverDisplayedMetadata()
//        [self resetVideoFiltersSliders];
        if playbackService.videoOutputView != videoOutputView {
            playbackService.videoOutputView = videoOutputView
        }
        subControls.repeatMode = playbackService.repeatMode

        // Media is loaded in the media player, checking the projection type and configuring accordingly.
        setupForMediaProjection()
    }

//    override func viewDidLayoutSubviews() {
        // FIXME: - equalizer
//        self.scrubViewTopConstraint.constant = CGRectGetMaxY(self.navigationController.navigationBar.frame);

  //  }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if playbackService.videoOutputView == videoOutputView {
            playbackService.videoOutputView = nil
        }
        // FIXME: -
//        _viewAppeared = NO;

        // FIXME: - interface
        if idleTimer != nil {
            idleTimer?.invalidate()
            idleTimer = nil
        }
        numberOfTapSeek = 0
        previousSeekState = .default
    }

    override var next: UIResponder? {
        get {
            resetIdleTimer()
            return super.next
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        deviceMotion.stopDeviceMotion()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        setupViews()
        setupGestures()
        setupConstraints()
    }
}

// MARK: -

private extension VideoPlayerViewController {
    @available(iOS 11.0, *)
    private func adaptVideoOutputToNotch() {
        // Ignore the constraint updates for iPads and notchless devices.
        let interfaceIdiom = UIDevice.current.userInterfaceIdiom
        if interfaceIdiom != .phone
            || (interfaceIdiom == .phone && view.safeAreaInsets.bottom == 0) {
            return
        }

        // Ignore if playing on a external screen since there is no notches.
        if playbackService.isPlayingOnExternalScreen() {
            return
        }

        // 30.0 represents the exact size of the notch
        let constant: CGFloat = playbackService.currentAspectRatio != .fillToScreen ? 30.0 : 0.0
        let interfaceOrientation = UIApplication.shared.statusBarOrientation

        if interfaceOrientation == .landscapeLeft
            || interfaceOrientation == .landscapeRight {
            videoOutputViewLeadingConstraint.constant = constant
            videoOutputViewTrailingConstraint.constant = -constant
        } else {
            videoOutputViewLeadingConstraint.constant = 0
            videoOutputViewTrailingConstraint.constant = 0
        }
        videoOutputView.layoutIfNeeded()
    }

    func changeVideoOuput(to view: UIView) {
        let shouldDisplayExternally = view != videoOutputView

        externalVideoOutput.shouldDisplay(shouldDisplayExternally, movieView: videoOutputView)

        let displayView = externalVideoOutput.displayView

        if let displayView = displayView,
            shouldDisplayExternally &&  videoOutputView.superview == displayView {
            // Adjust constraints for external display
            NSLayoutConstraint.activate([
                videoOutputView.leadingAnchor.constraint(equalTo: displayView.leadingAnchor),
                videoOutputView.trailingAnchor.constraint(equalTo: displayView.trailingAnchor),
                videoOutputView.topAnchor.constraint(equalTo: displayView.topAnchor),
                videoOutputView.bottomAnchor.constraint(equalTo: displayView.bottomAnchor)
            ])
        }

        if !shouldDisplayExternally && videoOutputView.superview != view {
            view.addSubview(videoOutputView)
            view.sendSubviewToBack(videoOutputView)
            videoOutputView.frame = view.frame
            // Adjust constraint for local display
            setupVideoOutputConstraints()
            if #available(iOS 11.0, *) {
                adaptVideoOutputToNotch()
            }
        }
    }

    @objc private func handleIdleTimerExceeded() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.handleIdleTimerExceeded()
            }
            return
        }

        idleTimer = nil
        numberOfTapSeek = 0
        if !playerController.isControlsHidden {
            setControlsHidden(!playerController.isControlsHidden, animated: true)
        }
        // FIXME:- other states to reset
    }

    private func resetIdleTimer() {
        guard let safeIdleTimer = idleTimer else {
            idleTimer = Timer.scheduledTimer(timeInterval: 4,
                                             target: self,
                                             selector: #selector(handleIdleTimerExceeded),
                                             userInfo: nil,
                                             repeats: false)
            return
        }

        if fabs(safeIdleTimer.fireDate.timeIntervalSinceNow) < 4 {
            safeIdleTimer.fireDate = Date(timeIntervalSinceNow: 4)
        }
    }

    private func executeSeekFromTap() {
        // FIXME: Need to add interface (ripple effect) for seek indicator

        let seekDuration: Int = numberOfTapSeek * VideoPlayerSeek.shortSeek

        if seekDuration > 0 {
            playbackService.jumpForward(Int32(VideoPlayerSeek.shortSeek))
            previousSeekState = .forward
        } else {
            playbackService.jumpBackward(Int32(VideoPlayerSeek.shortSeek))
            previousSeekState = .backward
        }
        // FIXME: - animation after seek yt
    }
}

// MARK: - Gesture handlers

extension VideoPlayerViewController {
    @objc func handleTapOnVideo() {
        // FIXME: -
        numberOfTapSeek = 0
        setControlsHidden(!playerController.isControlsHidden, animated: true)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if playbackService.isPlaying && playerController.isControlsHidden {
            setControlsHidden(false, animated: true)
        }
    }

    private func setControlsHidden(_ hidden: Bool, animated: Bool) {
        playerController.isControlsHidden = hidden
        let alpha: CGFloat = hidden ? 0 : 1

        UIView.animate(withDuration: animated ? 0.2 : 0) {
            // FIXME: retain cycle?
            self.mediaNavigationBar.alpha = alpha
            self.mainControls.alpha = alpha
            self.subControls.alpha = alpha
            self.scrubProgressBar.alpha = alpha
            self.shadowView.alpha = alpha
        }
    }

    @objc func handlePlayPauseGesture() {
        guard playerController.isPlayPauseGestureEnabled else {
            return
        }

        if playbackService.isPlaying {
            playbackService.pause()
            setControlsHidden(false, animated: playerController.isControlsHidden)
        } else {
            playbackService.play()
        }
    }

    @objc func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        if playbackService.currentMediaIs360Video {
            let zoom: CGFloat = MediaProjection.FOV.default * -(ZOOM_SENSITIVITY * recognizer.velocity / screenPixelSize.width)
            if playbackService.updateViewpoint(0, pitch: 0,
                                               roll: 0, fov: zoom, absolute: false) {
                // Clam FOV between min and max
                fov = max(min(fov + zoom, MediaProjection.FOV.max), MediaProjection.FOV.min)
            }
        } else if recognizer.velocity < 0
            && UserDefaults.standard.bool(forKey: kVLCSettingCloseGesture) {
            // minimize playback
            delegate?.videoPlayerViewControllerDidMinimize(self)
        }
    }

    @objc func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {
        let screenWidth: CGFloat = view.frame.size.width
        let backwardBoundary: CGFloat = screenWidth / 3.0
        let forwardBoundary: CGFloat = 2 * screenWidth / 3.0

        let tapPosition = recognizer.location(in: view)

        // Reset number(set to -1/1) of seek when orientation has been changed.
        if tapPosition.x < backwardBoundary {
            numberOfTapSeek = previousSeekState == .forward ? -1 : numberOfTapSeek - 1
        } else if tapPosition.x > forwardBoundary {
            numberOfTapSeek = previousSeekState == .backward ? 1 : numberOfTapSeek + 1
        } else {
            playbackService.switchAspectRatio(true)
        }
        //_isTapSeeking = YES;
        executeSeekFromTap()
    }
}

// MARK: - Private setups

private extension VideoPlayerViewController {
    private func setupViews() {
        view.addSubview(mediaNavigationBar)
        view.addSubview(mainControls)
        view.addSubview(subControls)
        view.addSubview(scrubProgressBar)

        view.addSubview(videoOutputView)
        view.sendSubviewToBack(videoOutputView)
        view.insertSubview(shadowView, aboveSubview: videoOutputView)
    }

    private func setupGestures() {
        view.addGestureRecognizer(tapOnVideoRecognizer)
        view.addGestureRecognizer(pinchRecognizer)
        view.addGestureRecognizer(doubleTapRecognizer)
        view.addGestureRecognizer(playPauseRecognizer)
    }

    // MARK: - Constraints

    private func setupConstraints() {
        setupVideoOutputConstraints()
        setupMediaNavigationBarConstraints()
        setupVideoPlayerMainControlConstraints()
        setupVideoPlayerSubControlConstraints()
        setupScrubProgressBarConstraints()
    }

    private func setupVideoOutputConstraints() {
        videoOutputViewLeadingConstraint = videoOutputView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        videoOutputViewTrailingConstraint = videoOutputView.trailingAnchor.constraint(equalTo: view.trailingAnchor)

        NSLayoutConstraint.activate([
            videoOutputViewLeadingConstraint,
            videoOutputViewTrailingConstraint,
            videoOutputView.topAnchor.constraint(equalTo: view.topAnchor),
            videoOutputView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupMediaNavigationBarConstraints() {
        let padding: CGFloat = 20

        NSLayoutConstraint.activate([
            mediaNavigationBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mediaNavigationBar.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor,
                                                        constant: padding),
            mediaNavigationBar.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor,
                                                         constant: -padding),
            mediaNavigationBar.topAnchor.constraint(equalTo: layoutGuide.topAnchor,
                                                    constant: padding)
        ])
    }

    private func setupVideoPlayerMainControlConstraints() {
//        let margin: CGFloat = 40

        NSLayoutConstraint.activate([
//            mainControls.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor,
//                                                  constant: margin),
//            mainControls.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor,
//                                                   constant: -margin),
            mainControls.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainControls.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//            mainControls.bottomAnchor.constraint(equalTo: subControls.topAnchor,
//                                                 constant: -margin)
        ])
    }

    private func setupVideoPlayerSubControlConstraints() {
        // FIXME: constant change on portrait/landscape
        NSLayoutConstraint.activate([
            subControls.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            subControls.topAnchor.constraint(equalTo: mainControls.bottomAnchor,
                                             constant: 50)
        ])
    }

    private func setupScrubProgressBarConstraints() {
        let margin: CGFloat = 10

        NSLayoutConstraint.activate([
            scrubProgressBar.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor,
                                                      constant: margin),
            scrubProgressBar.trailingAnchor.constraint(equalTo: layoutGuide.trailingAnchor,
                                                       constant: -margin),
            scrubProgressBar.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor, constant: -margin * 2)
        ])
    }

    // MARK: - Others

    private func setupForMediaProjection() {
        let mediaHasProjection = playbackService.currentMediaIs360Video

        fov = mediaHasProjection ? MediaProjection.FOV.default : 0
        // Disable swipe gestures.
        if mediaHasProjection {
            deviceMotion.startDeviceMotion()
        }
    }
}

// MARK: - Delegation

// MARK: - DeviceMotionDelegate

extension VideoPlayerViewController: DeviceMotionDelegate {
    func deviceMotionHasAttitude(deviceMotion: DeviceMotion, pitch: Double, yaw: Double) {
//        if (_panRecognizer.state != UIGestureRecognizerStateChanged || UIGestureRecognizerStateBegan) {
//            [self applyYaw:yaw pitch:pitch];
//        }
    }
}

// MARK: - VLCPlaybackServiceDelegate

extension VideoPlayerViewController: VLCPlaybackServiceDelegate {
    func prepare(forMediaPlayback playbackService: PlaybackService) {
        mediaNavigationBar.setMediaTitleLabelText("")
        // FIXME: -
        resetIdleTimer()
    }

    func playbackPositionUpdated(_ playbackService: PlaybackService) {
        scrubProgressBar.updateInterfacePosition()
    }

    func mediaPlayerStateChanged(_ currentState: VLCMediaPlayerState,
                                 isPlaying: Bool,
                                 currentMediaHasTrackToChooseFrom: Bool, currentMediaHasChapters: Bool,
                                 for playbackService: PlaybackService) {
        // FIXME -
        if currentState == .buffering {

        } else if currentState == .error {

        }
    }

    func savePlaybackState(_ playbackService: PlaybackService) {
        services.medialibraryService.savePlaybackState(from: playbackService)
    }

    func media(forPlaying media: VLCMedia?) -> VLCMLMedia? {
        return services.medialibraryService.fetchMedia(with: media?.url)
    }

    func showStatusMessage(_ statusMessage: String) {
        // FIXME
    }

    func playbackServiceDidSwitch(_ aspectRatio: VLCAspectRatio) {
        subControls.isInFullScreen = aspectRatio == .fillToScreen

        if #available(iOS 11.0, *) {
            adaptVideoOutputToNotch()
        }
    }

    func displayMetadata(for playbackService: PlaybackService, metadata: VLCMetaData) {
        // FIXME: -
//        if (!_viewAppeared)
//            return;
        if !isViewLoaded {
            return
        }
        mediaNavigationBar.setMediaTitleLabelText(metadata.title)

        if playbackService.isPlayingOnExternalScreen() {
            externalVideoOutput.updateUI(rendererItem: playbackService.renderer, title: metadata.title)
        }
//        subControls.toggleFullscreen().hidden = _audioOnly
    }
}

// MARK: - PlayerControllerDelegate

extension VideoPlayerViewController: PlayerControllerDelegate {
    func playerControllerExternalScreenDidConnect(_ playerController: PlayerController) {
        //        [self showOnDisplay:_playingExternalView.displayView];
    }

    func playerControllerExternalScreenDidDisconnect(_ playerController: PlayerController) {
        //        [self showOnDisplay:_movieView];
    }

    func playerControllerApplicationBecameActive(_ playerController: PlayerController) {
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

    func playerControllerPlaybackDidStop(_ playerController: PlayerController) {
        guard let delegate = delegate else {
            preconditionFailure("VideoPlayerViewController: Delegate not assigned.")
        }

        delegate.videoPlayerViewControllerDidMinimize(self)
        // Reset interface to default icon when dismissed
        subControls.isInFullScreen = false
    }
}

// MARK: -

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
            self.moreOptionsActionSheet.interfaceDisabled = self.playerController.isInterfaceLocked
        }
    }

    func didToggleInterfaceLock(_ optionsBar: VideoPlayerSubControl) {
        // toggleUILock
    }
}

// MARK: - MediaScrubProgressBarDelegate

extension VideoPlayerViewController: MediaScrubProgressBarDelegate {
    func mediaScrubProgressBarShouldResetIdleTimer() {
        resetIdleTimer()
    }
}

// MARK: - MediaMoreOptionsActionSheetDelegate

extension VideoPlayerViewController: MediaMoreOptionsActionSheetDelegate {
    func mediaMoreOptionsActionSheetDidToggleInterfaceLock(state: Bool) {
        //
    }
}
