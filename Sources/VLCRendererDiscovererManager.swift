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

    @objc dynamic var renderers: Array<VLCRendererItem> = [VLCRendererItem]()

    private override init() {
        super.init()
    }

    @objc func start() -> Bool {
        // Gather potential renderer discoverers
        guard let tmpDiscoverers: Array<VLCRendererDiscovererDescription> = VLCRendererDiscoverer.list() else {
            return false
        }

        for discoverer in tmpDiscoverers {
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
        return true
    }

    @objc func stop() {
        for discoverer in discoverers {
            discoverer.stop()
        }
    }
}

// MARK: VLCRendererDiscovererDelegate
extension VLCRendererDiscovererManager {
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        print("RendererDiscovererManager: New item added")
        renderers.append(item)
    }

    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        if let index = renderers.index(of: item) {
            //rendererItems should be deallocated here, therefore calling item_release
            print("RendererDiscovererManager: item removed")
            renderers.remove(at: index)
        } else {
            //might already be removed
            print("Issue while removing rendererItem: \(item)")
        }
    }
}
