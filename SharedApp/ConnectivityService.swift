import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

@MainActor
protocol ConnectivityDelegate: AnyObject {
    func connectivityDidReceive(_ envelope: SyncEnvelope)
    func connectivityDidUpdateStatus(_ status: WatchLinkStatus)
}

@MainActor
final class ConnectivityService: NSObject {
    weak var delegate: ConnectivityDelegate?
    private(set) var status: WatchLinkStatus = .unknown
    var localDevice: DeviceOrigin = .phone

    #if canImport(WatchConnectivity)
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }
    #endif

    func activate(localDevice: DeviceOrigin) {
        self.localDevice = localDevice
        #if canImport(WatchConnectivity)
        guard let session, WCSession.isSupported() else {
            status = .unsupported
            delegate?.connectivityDidUpdateStatus(status)
            return
        }
        session.delegate = self
        session.activate()
        refreshStatus()
        #else
        status = .unsupported
        delegate?.connectivityDidUpdateStatus(status)
        #endif
    }

    /// True only when a message can be delivered right now. Apple Watch drops this
    /// as soon as its screen sleeps, so it is not a measure of whether syncing works.
    var isImmediatelyReachable: Bool {
        #if canImport(WatchConnectivity)
        guard let session, session.activationState == .activated else { return false }
        return session.isReachable
        #else
        return false
        #endif
    }

    func refreshStatus() {
        #if canImport(WatchConnectivity)
        guard let session else {
            status = .unsupported
            delegate?.connectivityDidUpdateStatus(status)
            return
        }
        #if os(iOS)
        if session.activationState != .activated {
            status = .unknown
        } else if !session.isPaired {
            status = .unpaired
        } else if !session.isWatchAppInstalled {
            status = .appNotInstalled
        } else if session.isReachable {
            status = status == .pendingAck || status == .synced ? status : .reachable
        } else {
            status = .unreachable
        }
        #else
        if session.activationState != .activated {
            status = .unknown
        } else if session.isReachable {
            status = status == .pendingAck || status == .synced ? status : .reachable
        } else {
            status = .unreachable
        }
        #endif
        delegate?.connectivityDidUpdateStatus(status)
        #endif
    }

    func send(_ envelope: SyncEnvelope, preferImmediate: Bool) {
        guard let data = encode(envelope) else { return }
        #if canImport(WatchConnectivity)
        guard let session, session.activationState == .activated else { return }
        let payload: [String: Any] = ["json": data.base64EncodedString()]
        if preferImmediate && session.isReachable {
            session.sendMessage(payload, replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.handleReply(reply)
                }
            }, errorHandler: { [weak self] _ in
                session.transferUserInfo(payload)
                Task { @MainActor in
                    self?.status = .pendingAck
                    self?.delegate?.connectivityDidUpdateStatus(.pendingAck)
                }
            })
        } else {
            session.transferUserInfo(payload)
            if envelope.kind == .sessionStart || envelope.kind == .sessionRestart {
                status = session.isReachable ? .pendingAck : .unreachable
                delegate?.connectivityDidUpdateStatus(status)
            }
        }
        updateContext(envelope)
        #endif
    }

    func markSynced() {
        status = .synced
        delegate?.connectivityDidUpdateStatus(status)
    }

    func markPendingAck() {
        status = .pendingAck
        delegate?.connectivityDidUpdateStatus(status)
    }

    private func updateContext(_ envelope: SyncEnvelope) {
        #if canImport(WatchConnectivity)
        guard let session else { return }
        switch envelope.kind {
        case .fullState, .templates, .sessionStart, .sessionRestart, .sessionEnd, .sessionComplete:
            break
        case .testAlert, .ack:
            return
        }
        var context: [String: Any] = [:]
        if let data = encode(envelope) {
            context["json"] = data.base64EncodedString()
        }
        try? session.updateApplicationContext(context)
        #endif
    }

    private func decode(_ payload: [String: Any]) -> SyncEnvelope? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = payload["json"] as? Data {
            return try? decoder.decode(SyncEnvelope.self, from: data)
        }
        if let text = payload["json"] as? String {
            if let raw = Data(base64Encoded: text) {
                return try? decoder.decode(SyncEnvelope.self, from: raw)
            }
            if let raw = text.data(using: .utf8) {
                return try? decoder.decode(SyncEnvelope.self, from: raw)
            }
        }
        return nil
    }

    private func encode(_ envelope: SyncEnvelope) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(envelope)
    }

    private func handleIncoming(_ payload: [String: Any]) {
        guard let envelope = decode(payload) else { return }
        delegate?.connectivityDidReceive(envelope)
    }

    private func handleReply(_ payload: [String: Any]) {
        if let envelope = decode(payload) {
            delegate?.connectivityDidReceive(envelope)
        }
    }
}

#if canImport(WatchConnectivity)
extension ConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.refreshStatus()
        }
    }

    #if os(iOS)
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshStatus()
        }
    }
    #endif

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.refreshStatus()
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        Task { @MainActor in
            self.handleIncoming(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in
            self.handleIncoming(userInfo)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            self.handleIncoming(message)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            self.handleIncoming(message)
        }
        replyHandler(["ok": true])
    }
}
#endif
