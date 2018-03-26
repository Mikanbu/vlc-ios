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

class VLCRendererDiscovererManager: NSObject, VLCRendererDiscovererDelegate  {

    @objc static let sharedInstance = VLCRendererDiscovererManager();

    // Array of RendererDiscoverers(Chromecast, UPnP, ...)
    @objc dynamic var discoverers: Array<VLCRendererDiscoverer> = [VLCRendererDiscoverer]()

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
            if (discoverer.name == description.name) {
                return true
            }
        }
        return false
    }

    @objc func start() -> Bool {
        // Gather potential renderer discoverers
        guard let tmpDiscoverers: Array<VLCRendererDiscovererDescription> = VLCRendererDiscoverer.list() else {
            return false
        }
        for discoverer in tmpDiscoverers {

            if (!isDuplicateDiscoverer(with: discoverer)) {
                if let rendererDiscoverer = VLCRendererDiscoverer(name: discoverer.name) {
                    if (rendererDiscoverer.start()) {
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

// MARK: VLCRendererDiscovererDelegate
extension VLCRendererDiscovererManager {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        print("RendererDiscovererManager: New item added")
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        print("RendererDiscovererManager: item removed")
    }
}
