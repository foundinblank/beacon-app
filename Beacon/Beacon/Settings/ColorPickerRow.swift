import SwiftUI

struct ColorPickerRow: View {
    let label: String
    @Binding var colorHex: String

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
            Text(label)
                .fixedSize()
            Spacer()
            ForEach(Self.presetColors, id: \.name) { preset in
                Button {
                    colorHex = preset.hex
                } label: {
                    Circle()
                        .fill(preset.color)
                        .stroke(colorHex == preset.hex ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(preset.name)
            }
            ColorPicker("", selection: selectedColor, supportsOpacity: true)
                .labelsHidden()
                .accessibilityLabel("Custom \(label.lowercased())")
        }
    }
}
