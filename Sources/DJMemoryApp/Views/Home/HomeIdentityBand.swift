import SwiftUI
import DJMemoryCore

struct HomeIdentityBand: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Panel(padding: 14) {
            HStack(alignment: .top, spacing: 14) {
                monogram
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(HomeFormatting.greeting(profile: model.profile, now: model.previewNow ?? Date()))
                            .font(.system(size: DJToken.TypeSize.title, weight: .semibold))
                        Badge(title: model.protectionState.headline, tone: HomeFormatting.protectionTone(model.protectionState))
                        StatusDot(
                            tone: HomeFormatting.protectionTone(model.protectionState),
                            pulse: model.protectionState == .scanning
                        )
                    }

                    metaLineView

                    Rectangle().fill(DJToken.hairline).frame(height: 1).padding(.vertical, 4)
                    Text(adaptiveSentence)
                        .font(.system(size: DJToken.TypeSize.body))
                        .foregroundStyle(DJToken.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                VStack(spacing: 8) {
                    Button {
                        model.scanNow()
                    } label: {
                        Label(model.isScanning ? "Scanning…" : "Scan Now", systemImage: "waveform.badge.magnifyingglass")
                    }
                    .buttonStyle(DJPrimaryButtonStyle())
                    .disabled(model.isScanning)
                    .accessibilityIdentifier("home.scanNow")

                    Button("Open Library") {
                        model.openLibrary()
                    }
                    .buttonStyle(DJSecondaryButtonStyle())
                    .accessibilityIdentifier("home.openLibrary")
                }
            }
        }
    }

    private var monogram: some View {
        let accent = DJToken.accent(forAppID: model.librarySummaries.first?.archive.sourceAppID ?? "serato")
        return Group {
            if let initials = model.profile.initials {
                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
            } else {
                Image(systemName: "person")
                    .foregroundStyle(accent)
            }
        }
        .frame(width: 44, height: 44)
        .background(accent.opacity(0.08), in: RoundedRectangle(cornerRadius: DJToken.Radius.control))
        .overlay(
            RoundedRectangle(cornerRadius: DJToken.Radius.control)
                .stroke(accent.opacity(0.33), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var metaLineView: some View {
        let parts = metaParts
        if parts.isEmpty {
            Text("Local-first set archive")
                .font(.system(size: DJToken.TypeSize.secondary))
                .foregroundStyle(DJToken.mutedForeground)
        } else {
            HStack(spacing: 6) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if index > 0 {
                        Text("·")
                            .foregroundStyle(DJToken.mutedForeground)
                    }
                    switch part {
                    case .handle(let value):
                        Text(value)
                            .font(.system(size: DJToken.TypeSize.secondary, design: .monospaced))
                            .foregroundStyle(DJToken.mutedForeground)
                    case .city(let value):
                        HStack(spacing: 3) {
                            Image(systemName: "mappin")
                                .font(.system(size: 9, weight: .semibold))
                            Text(value)
                        }
                        .font(.system(size: DJToken.TypeSize.secondary))
                        .foregroundStyle(DJToken.mutedForeground)
                    case .text(let value):
                        Text(value)
                            .font(.system(size: DJToken.TypeSize.secondary))
                            .foregroundStyle(DJToken.mutedForeground)
                    }
                }
            }
        }
    }

    private enum MetaPart {
        case handle(String)
        case city(String)
        case text(String)
    }

    private var metaParts: [MetaPart] {
        var parts: [MetaPart] = []
        if let handle = model.profile.handle, !handle.isEmpty {
            parts.append(.handle(handle))
        }
        if let city = model.profile.city, !city.isEmpty {
            parts.append(.city(city))
        }
        if let residency = model.profile.residency, !residency.isEmpty {
            parts.append(.text(residency))
        }
        if let since = model.profile.memberSince {
            parts.append(.text("DJMemory since \(since.formatted(.dateTime.month().year()))"))
        }
        return parts
    }

    private var adaptiveSentence: String {
        let stats = model.libraryStatistics
        switch model.protectionState {
        case .protected:
            let weeks = stats.consecutiveWeeksRunning.map { " — you have \($0) weeks running with nothing lost" } ?? ""
            return "\(model.protectedAdapterCount) sources watched. Your last \(stats.setsThisMonth) sets this month were archived automatically\(weeks)."
        case .scanning:
            return "Checking \(model.protectedAdapterCount) watched folders for new recordings…"
        case .needsSetup:
            let remaining = model.probeResults.count - model.protectedAdapterCount
            return "\(model.protectedAdapterCount) of \(model.probeResults.count) sources watched. \(remaining) still need a folder before DJMemory can protect them."
        case .attentionNeeded:
            let app = model.unreachableRecordingAccesses().first.map { model.displayName(for: $0.appID) } ?? "a source"
            return "A saved folder is unavailable, so new sets from \(app) are not being archived right now. Everything already in your archive is safe."
        }
    }
}
