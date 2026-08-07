import Foundation

/// Sidebar / detail navigation. Replaces raw `String` route tags (`HANDOFF.md` §4.1).
enum Route: Hashable {
    case home
    case protection
    case library
    case activity
    case settings
    case app(String)
    case recovery(String)

    /// App id when this route is per-app setup or recovery; otherwise `nil`.
    var appID: String? {
        switch self {
        case .app(let id), .recovery(let id):
            return id
        case .home, .protection, .library, .activity, .settings:
            return nil
        }
    }
}
