/*****************************************************************************
 * VLCRendererDiscovererManager.swift
 *
 * Copyright © 2018 VLC authors and VideoLAN
 * Copyright © 2018 Videolabs
 *
 * Authors: Soomin Lee <bubu@mikan.io>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

class VLCRendererDiscovererManager: NSObject, VLCRendererDiscovererDelegate {

    @objc static let sharedInstance = VLCRendererDiscovererManager()

    // Array of RendererDiscoverers(Chromecast, UPnP, ...)
    @objc dynamic var discoverers: [VLCRendererDiscoverer] = [VLCRendererDiscoverer]()

    private override init() {
        super.init()
    }

    @objc func getAllRenderers() -> [VLCRendererItem] {
        var renderers = [VLCRendererItem]()

        for discoverer in discoverers {
            renderers += discoverer.renderers
        }
        return renderers
    }

    private func isDuplicateDiscoverer(with description: VLCRendererDiscovererDescription) -> Bool {
        for discoverer in discoverers {
            if discoverer.name == description.name {
                return true
            }
        }
        return false
    }

    @discardableResult @objc func start() -> Bool {
        // Gather potential renderer discoverers
        guard let tmpDiscoverers: [VLCRendererDiscovererDescription] = VLCRendererDiscoverer.list() else {
            return false
        }
        for discoverer in tmpDiscoverers {

            if !isDuplicateDiscoverer(with: discoverer) {
                if let rendererDiscoverer = VLCRendererDiscoverer(name: discoverer.name) {
                    if rendererDiscoverer.start() {
                        rendererDiscoverer.delegate = self
                        discoverers.append(rendererDiscoverer)
                    } else {
                        print("Unable to start renderer discoverer with name: \(rendererDiscoverer.name)")
                    }
                } else {
                    print("Unable to instanciate renderer discoverer with name: \(discoverer.name)")
                }
            }
        }

        return true
    }

    @objc func stop() {
        for discoverer in discoverers {
            discoverer.stop()
        }
        discoverers.removeAll()
    }
}

public extension Notification.Name {
    public static let rendererDiscovererItemAdded = NSNotification.Name("rendererDiscovererItemAdded")
    public static let rendererDiscovererItemRemoved = NSNotification.Name("rendererDiscovererItemRemoved")
}

@objc extension NSNotification {
    static let rendererDiscovererItemAdded = NSNotification.Name.rendererDiscovererItemAdded
    static let rendererDiscovererItemRemoved = NSNotification.Name.rendererDiscovererItemAdded
}

// MARK: VLCRendererDiscovererDelegate
extension VLCRendererDiscovererManager {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        NotificationCenter.default.post(name: .rendererDiscovererItemAdded, object: item)
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        NotificationCenter.default.post(name: .rendererDiscovererItemRemoved, object: item)
    }
}
