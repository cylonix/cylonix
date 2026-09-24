// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)
        BackgroundTaskManager.shared.processFilesFromSharedContainer { _ in }
        // A share handed over by the share extension ("send as peer
        // message") brings the app forward; the manifest waits on disk.
        (UIApplication.shared.delegate as? AppDelegate)?.processPendingShareRequests()
    }
}
