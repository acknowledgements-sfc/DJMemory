import SwiftUI

struct DJPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DJToken.TypeSize.body, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(
                DJToken.primary.opacity(configuration.isPressed ? 0.85 : 1),
                in: RoundedRectangle(cornerRadius: DJToken.Radius.control)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DJToken.Radius.control)
                    .stroke(DJToken.primary, lineWidth: 1)
            )
    }
}

struct DJSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DJToken.TypeSize.body, weight: .medium))
            .foregroundStyle(DJToken.foreground)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(
                (configuration.isPressed ? DJToken.secondary : DJToken.elevated),
                in: RoundedRectangle(cornerRadius: DJToken.Radius.control)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DJToken.Radius.control)
                    .stroke(DJToken.border, lineWidth: 1)
            )
    }
}

struct DJGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DJToken.TypeSize.body, weight: .medium))
            .foregroundStyle(configuration.isPressed ? DJToken.foreground : DJToken.mutedForeground)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(
                configuration.isPressed ? DJToken.secondary.opacity(0.7) : Color.clear,
                in: RoundedRectangle(cornerRadius: DJToken.Radius.control)
            )
    }
}

struct DJDangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: DJToken.TypeSize.body, weight: .medium))
            .foregroundStyle(DJToken.danger)
            .padding(.horizontal, 10)
            .frame(minHeight: 28)
            .background(
                configuration.isPressed ? DJToken.danger.opacity(0.1) : Color.clear,
                in: RoundedRectangle(cornerRadius: DJToken.Radius.control)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DJToken.Radius.control)
                    .stroke(DJToken.border, lineWidth: 1)
            )
    }
}

#Preview("Button styles") {
    HStack(spacing: 8) {
        Button("Primary") {}
            .buttonStyle(DJPrimaryButtonStyle())
        Button("Secondary") {}
            .buttonStyle(DJSecondaryButtonStyle())
        Button("Ghost") {}
            .buttonStyle(DJGhostButtonStyle())
        Button("Danger") {}
            .buttonStyle(DJDangerButtonStyle())
    }
    .padding()
    .background(DJToken.content)
}
