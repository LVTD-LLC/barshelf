import Foundation

public enum VisibilityMode: String, CaseIterable, Codable, Equatable {
    case alwaysShown
    case floatingShelf
    case alwaysHidden

    public var label: String {
        switch self {
        case .alwaysShown: return "Always shown"
        case .floatingShelf: return "Floating shelf"
        case .alwaysHidden: return "Always hidden"
        }
    }
}

public struct MenuBarItemIdentity: Equatable {
    public let owner: String
    public let name: String
    public let roundedX: Int

    public init(owner: String, name: String, roundedX: Int) {
        self.owner = owner
        self.name = name
        self.roundedX = roundedX
    }

    public var id: String {
        let stableName = name.isEmpty ? "status-item" : name
        return "\(owner)|\(stableName)|\(roundedX)"
    }

    public var displayName: String {
        if name.isEmpty { return owner }
        return "\(owner) — \(name)"
    }
}

public enum VisibilityModeCodec {
    public static func encode(_ modes: [String: VisibilityMode]) throws -> Data {
        let raw = modes.mapValues(\.rawValue)
        return try JSONEncoder().encode(raw)
    }

    public static func decode(_ data: Data?) -> [String: VisibilityMode] {
        guard let data,
              let raw = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return raw.compactMapValues(VisibilityMode.init(rawValue:))
    }
}
