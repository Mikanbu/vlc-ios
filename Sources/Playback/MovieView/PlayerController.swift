/*****************************************************************************
 * PlayerController.swift
 *
 * Copyright © 2020 VLC authors and VideoLAN
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

struct MediaProjection {
    struct FOV {
        static let `default`: CGFloat = 80
        static let max: CGFloat = 150
        static let min: CGFloat = 20
    }
}

protocol PlayerControllerDelegate: class {
    func playerControllerExternalScreenDidConnect(_ playerController: PlayerController)
    func playerControllerExternalScreenDidDisconnect(_ playerController: PlayerController)
    func playerControllerApplicationBecameActive(_ playerController: PlayerController)
    func playerControllerPlaybackDidStop(_ playerController: PlayerController)
}

@objc(VLCPlayerController)
class PlayerController: NSObject {
    weak var delegate: PlayerControllerDelegate?

    private var services: Services

    private var playbackService: PlaybackService = PlaybackService.sharedInstance()

    // MARK: - States

    var isInterfaceLocked: Bool = false
    var isTapSeeking: Bool = false

    @objc init(services: Services) {
        self.services = services
        super.init()
        setupObservers()
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
}

// MARK: - Observers

extension PlayerController {
    @objc func handleExternalScreenDidConnect() {
        delegate?.playerControllerExternalScreenDidConnect(self)
    }

    @objc func handleExternalScreenDidDisconnect() {
        delegate?.playerControllerExternalScreenDidDisconnect(self)
    }

    @objc func handleAppBecameActive() {
        delegate?.playerControllerApplicationBecameActive(self)
    }

    @objc func handlePlaybackDidStop() {
        delegate?.playerControllerPlaybackDidStop(self)
    }
}
