// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)
        BackgroundTaskManager.shared.processFilesFromSharedContainer { _ in }
    }
}
