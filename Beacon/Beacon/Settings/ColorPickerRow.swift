import SwiftUI

struct ColorPickerRow: View {
    let label: String
    @Binding var colorHex: String
    var subtitle: String? = nil
    @Environment(\.isEnabled) private var isEnabled

    private var selectedColor: Binding<Color> {
        Binding(
            get: { Color(NSColor(hex: colorHex) ?? .red) },
            set: { colorHex = NSColor($0).hexString }
        )
    }

    private static let presetColors: [(name: String, color: Color, hex: String)] = [
        ("Red", .red, NSColor.red.hexString),
        ("Yellow", .yellow, NSColor.yellow.hexString),
        ("Green", .green, NSColor.green.hexString),
        ("Cyan", .cyan, NSColor.cyan.hexString),
        ("Blue", .blue, NSColor.blue.hexString),
        ("Magenta", Color(nsColor: .magenta), NSColor.magenta.hexString),
        ("White", .white, NSColor.white.hexString),
        ("Black", .black, NSColor.black.hexString),
    ]

    var body: some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .fixedSize()
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }
            }
            Spacer()
            ForEach(Self.presetColors, id: \.name) { preset in
                let isSelected = colorHex == preset.hex
                Button {
                    colorHex = preset.hex
                } label: {
                    Circle()
                        .fill(preset.color)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                        .saturation(isEnabled ? 1 : 0)
                        .opacity(isEnabled ? 1 : 0.4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(preset.name)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityHint("Select \(preset.name.lowercased()) as \(label.lowercased())")
            }
            ColorPicker("", selection: selectedColor, supportsOpacity: true)
                .labelsHidden()
                .accessibilityLabel("Custom \(label.lowercased())")
                .saturation(isEnabled ? 1 : 0)
                .opacity(isEnabled ? 1 : 0.4)
        }
    }
}
