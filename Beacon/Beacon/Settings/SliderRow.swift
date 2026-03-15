import SwiftUI

struct SliderRow: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    @ScaledMetric(relativeTo: .body) private var valueWidth: CGFloat = 50

    var body: some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(label)
                .accessibilityValue(format(value.wrappedValue))
            Text(format(value.wrappedValue))
                .monospacedDigit()
                .frame(minWidth: valueWidth, alignment: .trailing)
        }
    }
}
