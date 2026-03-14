import SwiftUI

struct CrosshairSettingsSection: View {
    @AppStorage(SettingsKeys.crosshairColor) private var colorHex = SettingsDefaults.crosshairColor
    @AppStorage(SettingsKeys.crosshairThickness) private var thickness = SettingsDefaults.crosshairThickness
    @AppStorage(SettingsKeys.crosshairLineStyle) private var lineStyle = SettingsDefaults.crosshairLineStyle
    @AppStorage(SettingsKeys.crosshairDashLength) private var dashLength = SettingsDefaults.crosshairDashLength
    @AppStorage(SettingsKeys.crosshairGapLength) private var gapLength = SettingsDefaults.crosshairGapLength

    private var selectedColor: Binding<Color> {
        Binding(
            get: { Color(NSColor(hex: colorHex) ?? SettingsDefaults.crosshairNSColor) },
            set: { colorHex = NSColor($0).hexString }
        )
    }

    private static let presetColors: [(name: String, color: Color, hex: String)] = [
        ("Red", .red, NSColor.red.hexString),
        ("Yellow", .yellow, NSColor.yellow.hexString),
        ("Green", .green, NSColor.green.hexString),
        ("Cyan", .cyan, NSColor.cyan.hexString),
        ("Blue", .blue, NSColor.blue.hexString),
        ("Magenta", .purple, NSColor.purple.hexString),
        ("White", .white, NSColor.white.hexString),
        ("Black", .black, NSColor.black.hexString),
    ]

    var body: some View {
        Section("Crosshair") {
            HStack(spacing: 8) {
                Text("Color")
                Spacer()
                ForEach(Self.presetColors, id: \.name) { preset in
                    Circle()
                        .fill(preset.color)
                        .stroke(colorHex == preset.hex ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            colorHex = preset.hex
                        }
                        .accessibilityLabel(preset.name)
                }
                ColorPicker("", selection: selectedColor, supportsOpacity: true)
                    .labelsHidden()
                    .accessibilityLabel("Custom color")
            }

            sliderRow("Thickness", value: $thickness, range: 1...10, step: 0.5) {
                String(format: "%.1f px", $0)
            }

            Picker("Line Style", selection: $lineStyle) {
                Text("Solid").tag(LineStyle.solid.rawValue)
                Text("Dashed").tag(LineStyle.dashed.rawValue)
                Text("Dotted").tag(LineStyle.dotted.rawValue)
            }

            if lineStyle != LineStyle.solid.rawValue {
                sliderRow("Dash Length", value: $dashLength, range: 1...20, step: 1) {
                    "\(Int($0)) px"
                }

                sliderRow("Gap Length", value: $gapLength, range: 1...20, step: 1) {
                    "\(Int($0)) px"
                }
            }
        }
    }

    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) -> some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text(format(value.wrappedValue))
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }
}
