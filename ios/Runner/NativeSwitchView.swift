// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

#if os(iOS)
    import Flutter
    import UIKit

    class NativeSwitchViewFactory: NSObject, FlutterPlatformViewFactory {
        private let messenger: FlutterBinaryMessenger

        init(messenger: FlutterBinaryMessenger) {
            self.messenger = messenger
        }

        func create(
            withFrame frame: CGRect,
            viewIdentifier viewId: Int64,
            arguments args: Any?
        ) -> FlutterPlatformView {
            NativeSwitchView(frame: frame, viewId: viewId, messenger: messenger, args: args)
        }

        func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
            FlutterStandardMessageCodec.sharedInstance()
        }
    }

    class NativeSwitchView: NSObject, FlutterPlatformView {
        private let switchControl = UISwitch()
        private let channel: FlutterMethodChannel

        init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
            channel = FlutterMethodChannel(
                name: "io.cylonix/uiswitch/\(viewId)",
                binaryMessenger: messenger
            )
            super.init()

            if let params = args as? [String: Any] {
                switchControl.isOn = params["value"] as? Bool ?? false
                if let enabled = params["enabled"] as? Bool {
                    switchControl.isEnabled = enabled
                }
            }

            switchControl.addTarget(self, action: #selector(valueChanged), for: .valueChanged)

            // Report the native intrinsic size to Flutter so it can size the
            // SizedBox exactly — no guessing needed.
            let sz = switchControl.intrinsicContentSize
            channel.invokeMethod("intrinsicSize", arguments: ["width": sz.width, "height": sz.height])

            channel.setMethodCallHandler { [weak self] call, result in
                guard let self = self else {
                    result(FlutterMethodNotImplemented)
                    return
                }
                if call.method == "setValue", let v = call.arguments as? Bool {
                    self.switchControl.setOn(v, animated: true)
                    result(nil)
                } else if call.method == "setEnabled", let e = call.arguments as? Bool {
                    self.switchControl.isEnabled = e
                    result(nil)
                } else if call.method == "setHidden", let hidden = call.arguments as? Bool {
                    self.switchControl.isHidden = hidden
                    result(nil)
                } else if call.method == "setAppearance", let appearance = call.arguments as? String {
                    self.switchControl.overrideUserInterfaceStyle = appearance == "dark" ? .dark : .light
                    result(nil)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        @objc private func valueChanged() {
            channel.invokeMethod("onChanged", arguments: switchControl.isOn)
        }

        func view() -> UIView { switchControl }
    }

#elseif os(macOS)
    import AppKit
    import FlutterMacOS

    class NativeSwitchViewFactory: NSObject, FlutterPlatformViewFactory {
        private let messenger: FlutterBinaryMessenger

        init(messenger: FlutterBinaryMessenger) {
            self.messenger = messenger
        }

        func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
            NativeSwitchView(viewId: viewId, messenger: messenger, args: args)
        }

        func createArgsCodec() -> (any FlutterMessageCodec & NSObjectProtocol)? {
            FlutterStandardMessageCodec.sharedInstance()
        }
    }

    class NativeSwitchView: NSView {
        private let switchControl = NSSwitch()
        private let channel: FlutterMethodChannel

        init(viewId: Int64, messenger: FlutterBinaryMessenger, args: Any?) {
            channel = FlutterMethodChannel(
                name: "io.cylonix/uiswitch/\(viewId)",
                binaryMessenger: messenger
            )
            super.init(frame: .zero)

            if let params = args as? [String: Any] {
                switchControl.state = (params["value"] as? Bool ?? false) ? .on : .off
                if let enabled = params["enabled"] as? Bool {
                    switchControl.isEnabled = enabled
                }
            }

            switchControl.target = self
            switchControl.action = #selector(valueChanged)

            addSubview(switchControl)
            switchControl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                switchControl.centerXAnchor.constraint(equalTo: centerXAnchor),
                switchControl.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])

            channel.setMethodCallHandler { [weak self] call, result in
                guard let self = self else {
                    result(FlutterMethodNotImplemented)
                    return
                }
                if call.method == "setValue", let v = call.arguments as? Bool {
                    self.switchControl.state = v ? .on : .off
                    result(nil)
                } else if call.method == "setEnabled", let e = call.arguments as? Bool {
                    self.switchControl.isEnabled = e
                    result(nil)
                } else if call.method == "setAppearance", let appearance = call.arguments as? String {
                    self.appearance = NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)
                    result(nil)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func valueChanged() {
            channel.invokeMethod("onChanged", arguments: switchControl.state == .on)
        }
    }
#endif
