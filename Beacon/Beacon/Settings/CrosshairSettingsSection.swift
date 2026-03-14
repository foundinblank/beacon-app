import SwiftUI

struct CrosshairSettingsSection: View {
    @AppStorage(SettingsKeys.crosshairColor) private var colorHex = SettingsDefaults.crosshairColor
    @AppStorage(SettingsKeys.crosshairThickness) private var thickness = SettingsDefaults.crosshairThickness
    @AppStorage(SettingsKeys.crosshairLineStyle) private var lineStyle = SettingsDefaults.crosshairLineStyle
    @AppStorage(SettingsKeys.crosshairDashLength) private var dashLength = SettingsDefaults.crosshairDashLength
    @AppStorage(SettingsKeys.crosshairGapLength) private var gapLength = SettingsDefaults.crosshairGapLength

    private var selectedColor: Binding<Color> {
        Binding(
            get: { Color(NSColor(hex: colorHex) ?? .red) },
            set: { colorHex = NSColor($0).hexString }
        )
    }

    private static let presetColors: [(String, Color)] = [
        ("Red", .red),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Cyan", .cyan),
        ("Blue", .blue),
        ("Magenta", .purple),
        ("White", .white),
        ("Black", .black),
    ]

    var body: some View {
        Section("Crosshair") {
            HStack(spacing: 8) {
                Text("Color")
                Spacer()
                ForEach(Self.presetColors, id: \.0) { name, color in
                    Circle()
                        .fill(color)
                        .stroke(colorHex == NSColor(color).hexString ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .onTapGesture {
                            colorHex = NSColor(color).hexString
                        }
                        .accessibilityLabel(name)
                }
                ColorPicker("", selection: selectedColor, supportsOpacity: true)
                    .labelsHidden()
                    .accessibilityLabel("Custom color")
            }

            HStack {
                Text("Thickness")
                Slider(value: $thickness, in: 1...10, step: 0.5)
                Text("\(thickness, specifier: "%.1f") px")
                    .monospacedDigit()
                    .frame(width: 50, alignment: .trailing)
            }

            Picker("Line Style", selection: $lineStyle) {
                Text("Solid").tag("solid")
                Text("Dashed").tag("dashed")
                Text("Dotted").tag("dotted")
            }

            if lineStyle != "solid" {
                HStack {
                    Text("Dash Length")
                    Slider(value: $dashLength, in: 1...20, step: 1)
                    Text("\(Int(dashLength)) px")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }

                HStack {
                    Text("Gap Length")
                    Slider(value: $gapLength, in: 1...20, step: 1)
                    Text("\(Int(gapLength)) px")
                        .monospacedDigit()
                        .frame(width: 50, alignment: .trailing)
                }
            }
        }
    }
}
