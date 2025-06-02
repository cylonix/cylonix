import Foundation

class TunnelNotificationListener: NSObject, CylonixTunnelNotifierListenerXPCProtocol, NSSecureCoding {
    static let shared = TunnelNotificationListener()

    var connection: NSXPCConnection?
    private var notificationHandler: ((String) -> Void)?

    // Required by NSSecureCoding
    static var supportsSecureCoding: Bool {
        return true
    }

    // Required initializer for NSSecureCoding
    required init?(coder _: NSCoder) {
        super.init()
    }

    // Required method for NSSecureCoding
    func encode(with _: NSCoder) {
        // No properties need to be encoded
    }

    override init() {
        super.init()
    }

    func startListening(handler: @escaping (String) -> Void) {
        notificationHandler = handler
        wg_log(.debug, message: "Starting XPC connection setup")
        connection = NSXPCConnection(machServiceName: "io.cylonix.sase.TunnelNotifier")
        guard let connection = connection else {
            wg_log(.debug, message: "Failed to create NSXPCConnection")
            return
        }
        connection.remoteObjectInterface = NSXPCInterface(with: CylonixTunnelNotifierXPCProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: CylonixTunnelNotifierListenerXPCProtocol.self)
        connection.exportedObject = self
        connection.invalidationHandler = { [weak self] in
            wg_log(.debug, message: "XPC connection invalidated")
            self?.connection = nil
        }
        connection.interruptionHandler = { [weak self] in
            wg_log(.debug, message: "XPC connection interrupted")
            self?.connection = nil
        }
        wg_log(.debug, message: "Resuming XPC connection")
        connection.resume()
        if let service = connection.remoteObjectProxyWithErrorHandler({ error in
            wg_log(.debug, message: "Failed to get remote object proxy: \(error)")
        }) as? TunnelNotifierXPCProtocol {
            wg_log(.debug, message: "Registering listener with XPC service")
            service.registerListener(self)
        } else {
            wg_log(.debug, message: "Failed to cast remote object proxy to TunnelNotifierXPCProtocol")
        }
    }

    func didReceiveNotification(_ notification: String) {
        DispatchQueue.main.async { [weak self] in
            self?.notificationHandler?(notification)
        }
    }

    func invalidate() {
        wg_log(.debug, message: "Invalidating XPC connection")
        connection?.invalidate()
        connection = nil
    }

    deinit {
        wg_log(.debug, message: "Deinitializing TunnelNotificationListener")
        invalidate()
    }
}
