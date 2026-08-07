import AVFoundation
import Foundation

public struct AudioInputDevice: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let manufacturer: String

    public init(id: String, name: String, manufacturer: String) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
    }

    public var isLikelyPioneerDJHardware: Bool {
        let haystack = "\(name) \(manufacturer)".lowercased()
        return ["djm", "xdj", "cdj", "pioneer"].contains { haystack.contains($0) }
    }
}

public enum AudioInputDeviceCatalog {
    public static func listInputs() -> [AudioInputDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.microphone, .external],
            mediaType: .audio,
            position: .unspecified
        )
        let devices = session.devices.map {
            AudioInputDevice(id: $0.uniqueID, name: $0.localizedName, manufacturer: $0.manufacturer)
        }
        return devices.sorted { lhs, rhs in
            if lhs.isLikelyPioneerDJHardware != rhs.isLikelyPioneerDJHardware {
                return lhs.isLikelyPioneerDJHardware && !rhs.isLikelyPioneerDJHardware
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    public static func preferredDefault(from devices: [AudioInputDevice] = listInputs()) -> AudioInputDevice? {
        devices.first(where: \.isLikelyPioneerDJHardware) ?? devices.first
    }
}
