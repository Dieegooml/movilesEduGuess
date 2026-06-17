import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private(set) var isConnected = true
    private var handlers: [(Bool) -> Void] = []

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let status = path.status == .satisfied
            self?.isConnected = status
            self?.handlers.forEach { $0(status) }
        }
        monitor.start(queue: queue)
    }

    func onChange(_ handler: @escaping (Bool) -> Void) {
        handler(isConnected)
        handlers.append(handler)
    }
}
