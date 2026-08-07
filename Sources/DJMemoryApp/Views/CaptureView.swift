import SwiftUI
import DJMemoryCore

struct CaptureView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Capture")
                    .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
                Spacer()
                SupportBadge(status: .manualSetup)
            }

            Text("Record the master mix from a DJM USB input into your DJMemory archive. USB MASTER REC sticks stay untouched—add Pioneer Hardware to watch PIONEERREC.")
                .font(.system(size: DJToken.TypeSize.body))
                .foregroundStyle(DJToken.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            Panel(title: "Input", padding: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    if model.captureState.devices.isEmpty {
                        Text("No audio inputs found.")
                            .font(.system(size: DJToken.TypeSize.body))
                            .foregroundStyle(DJToken.mutedForeground)
                    } else {
                        Picker("Device", selection: Binding(
                            get: { model.captureState.selectedDeviceID },
                            set: { if let v = $0 { model.selectCaptureDevice(v) } }
                        )) {
                            ForEach(model.captureState.devices) { device in
                                Text(device.manufacturer.isEmpty ? device.name : "\(device.name) (\(device.manufacturer))")
                                    .tag(Optional(device.id))
                            }
                        }
                        .accessibilityIdentifier("capture.devicePicker")
                    }
                    Button("Refresh Devices") { model.refreshAudioInputs() }
                        .accessibilityIdentifier("capture.refreshDevices")
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: DJToken.Radius.badge).fill(DJToken.muted)
                            RoundedRectangle(cornerRadius: DJToken.Radius.badge).fill(DJToken.ok)
                                .frame(width: max(4, proxy.size.width * CGFloat(model.captureState.inputLevel)))
                        }
                    }
                    .frame(height: 8)
                    .accessibilityIdentifier("capture.levelMeter")
                }
            }

            Panel(title: "Session", padding: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.captureState.statusMessage)
                        .font(.system(size: DJToken.TypeSize.body))
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        if model.captureState.isRecording || model.captureState.phase == .saving {
                            Button("Stop") { model.stopCapture() }
                                .buttonStyle(DJPrimaryButtonStyle())
                                .disabled(model.captureState.phase == .saving)
                                .accessibilityIdentifier("capture.stop")
                        } else {
                            Button("Start") { model.startCapture() }
                                .buttonStyle(DJPrimaryButtonStyle())
                                .disabled(model.captureState.devices.isEmpty || model.captureState.phase == .requestingPermission)
                                .accessibilityIdentifier("capture.start")
                        }
                        if case .failed = model.captureState.phase {
                            Button("Open Microphone Settings") { model.openMicrophonePrivacySettings() }
                                .accessibilityIdentifier("capture.openPrivacySettings")
                        }
                        if model.captureState.lastArchivedSessionID != nil {
                            Button("Open Library") { model.selectedRoute = .library }
                                .accessibilityIdentifier("capture.openLibrary")
                        }
                    }
                }
            }

            Panel(title: "Hardware tips", padding: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(SupportedHardware.all.prefix(4)) { profile in
                        Text("\(profile.displayName): \(profile.captureHint)")
                            .font(.system(size: DJToken.TypeSize.secondary))
                            .foregroundStyle(DJToken.mutedForeground)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("CDJs need a DJM or an all-in-one MASTER REC path.")
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.warn)
                }
            }
        }
        .onAppear { model.refreshAudioInputs() }
    }
}

#if DEBUG
#Preview("Capture idle") {
    let model = AppModel()
    model.previewApplyCaptureState(CaptureUIState(
        phase: .armed,
        devices: [AudioInputDevice(id: "djm", name: "DJM-V10", manufacturer: "Pioneer DJ")],
        selectedDeviceID: "djm"
    ))
    return CaptureView().environmentObject(model).frame(width: 720, height: 560).preferredColorScheme(.dark)
}
#endif
