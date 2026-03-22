import SwiftUI

struct SliderRow: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    @ScaledMetric(relativeTo: .body) private var labelWidth: CGFloat = 140
    @ScaledMetric(relativeTo: .body) private var valueWidth: CGFloat = 50

    private var snappedValue: Binding<Double> {
        Binding(
            get: { value.wrappedValue },
            set: { newValue in
                value.wrappedValue = (newValue / step).rounded() * step
            }
        )
    }

    var body: some View {
        HStack {
            Text(label)
                .frame(width: labelWidth, alignment: .leading)
            Slider(value: snappedValue, in: range)
                .accessibilityLabel(label)
                .accessibilityValue(format(value.wrappedValue))
            Text(format(value.wrappedValue))
                .monospacedDigit()
                .frame(minWidth: valueWidth, alignment: .trailing)
        }
    }
}
