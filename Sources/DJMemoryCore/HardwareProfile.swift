import Foundation

public enum HardwareClass: String, Codable, Sendable {
    case mixer
    case allInOne
    case player
}

public struct HardwareProfile: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let hardwareClass: HardwareClass
    public let captureHint: String
    public let usbRecFolderHint: String?
    public let needsMixerForMaster: Bool

    public init(id: String, displayName: String, hardwareClass: HardwareClass, captureHint: String, usbRecFolderHint: String?, needsMixerForMaster: Bool) {
        self.id = id
        self.displayName = displayName
        self.hardwareClass = hardwareClass
        self.captureHint = captureHint
        self.usbRecFolderHint = usbRecFolderHint
        self.needsMixerForMaster = needsMixerForMaster
    }
}

public enum SupportedHardware {
    public static let pioneerUSBRecFolderName = "PIONEERREC"

    public static let all: [HardwareProfile] = [
        HardwareProfile(id: "xdj-rx2", displayName: "XDJ-RX2", hardwareClass: .allInOne, captureHint: "Prefer MASTER REC to USB (PIONEERREC). Use Capture when this unit or a DJM appears as a Core Audio input.", usbRecFolderHint: pioneerUSBRecFolderName, needsMixerForMaster: false),
        HardwareProfile(id: "xdj-rx3", displayName: "XDJ-RX3", hardwareClass: .allInOne, captureHint: "MASTER REC writes WAV files to PIONEERREC on USB port 2.", usbRecFolderHint: pioneerUSBRecFolderName, needsMixerForMaster: false),
        HardwareProfile(id: "xdj-xz", displayName: "XDJ-XZ", hardwareClass: .allInOne, captureHint: "MASTER REC to USB (PIONEERREC) is the primary archive path.", usbRecFolderHint: pioneerUSBRecFolderName, needsMixerForMaster: false),
        HardwareProfile(id: "xdj-az", displayName: "XDJ-AZ", hardwareClass: .allInOne, captureHint: "Archive MASTER REC from PIONEERREC, or Capture via DJM USB input.", usbRecFolderHint: pioneerUSBRecFolderName, needsMixerForMaster: false),
        HardwareProfile(id: "cdj-2000", displayName: "CDJ-2000", hardwareClass: .player, captureHint: "CDJs do not record the master mix. Route through a DJM and use Capture.", usbRecFolderHint: nil, needsMixerForMaster: true),
        HardwareProfile(id: "cdj-2000nxs", displayName: "CDJ-2000NXS", hardwareClass: .player, captureHint: "CDJs do not record the master mix. Route through a DJM and use Capture.", usbRecFolderHint: nil, needsMixerForMaster: true),
        HardwareProfile(id: "cdj-3000", displayName: "CDJ-3000", hardwareClass: .player, captureHint: "CDJs do not record the master mix. Route through a DJM and use Capture.", usbRecFolderHint: nil, needsMixerForMaster: true),
        HardwareProfile(id: "djm-900", displayName: "DJM-900", hardwareClass: .mixer, captureHint: "Install Pioneer DJM USB driver. Assign MIX (REC OUT), then select the DJM in Capture.", usbRecFolderHint: nil, needsMixerForMaster: false),
        HardwareProfile(id: "djm-v10", displayName: "DJM-V10", hardwareClass: .mixer, captureHint: "Install Pioneer DJM-V10 USB driver. Assign MIX (REC OUT), then select in Capture.", usbRecFolderHint: nil, needsMixerForMaster: false),
        HardwareProfile(id: "djm-v10lf", displayName: "DJM-V10LF", hardwareClass: .mixer, captureHint: "Install Pioneer DJM-V10LF USB driver. Assign MIX (REC OUT), then select in Capture.", usbRecFolderHint: nil, needsMixerForMaster: false)
    ]

    public static func profile(id: String) -> HardwareProfile? {
        all.first { $0.id == id }
    }
}
