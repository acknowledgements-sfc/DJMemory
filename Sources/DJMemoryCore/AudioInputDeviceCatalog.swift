import CoreAudio
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
        let devices = coreAudioInputDevices()
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

    private static func coreAudioInputDevices() -> [AudioInputDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        let systemObject = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(systemObject, &address, 0, nil, &dataSize) == noErr,
              dataSize > 0
        else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var ids = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(systemObject, &address, 0, nil, &dataSize, &ids) == noErr else {
            return []
        }

        return ids.compactMap { deviceID in
            guard inputChannelCount(deviceID) > 0 else { return nil }
            let uid = cfStringProperty(deviceID, kAudioDevicePropertyDeviceUID)
            guard !uid.isEmpty else { return nil }
            let name = cfStringProperty(deviceID, kAudioObjectPropertyName)
            let manufacturer = cfStringProperty(deviceID, kAudioObjectPropertyManufacturer)
            return AudioInputDevice(id: uid, name: name, manufacturer: manufacturer)
        }
    }

    private static func inputChannelCount(_ deviceID: AudioDeviceID) -> Int {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(deviceID, &address, 0, nil, &dataSize) == noErr,
              dataSize > 0
        else { return 0 }

        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: Int(dataSize),
            alignment: MemoryLayout<AudioBufferList>.alignment
        )
        defer { raw.deallocate() }
        guard AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, raw) == noErr else {
            return 0
        }
        let list = raw.assumingMemoryBound(to: AudioBufferList.self)
        return UnsafeMutableAudioBufferListPointer(list).reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    private static func cfStringProperty(
        _ deviceID: AudioDeviceID,
        _ selector: AudioObjectPropertySelector
    ) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var value: Unmanaged<CFString>?
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &dataSize, &value)
        guard status == noErr, let value else { return "" }
        return value.takeRetainedValue() as String
    }
}
