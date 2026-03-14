import SwiftUI

struct SliderRow: View {
    let label: String
    let value: Binding<Double>
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        HStack {
            Text(label)
            Slider(value: value, in: range, step: step)
            Text(format(value.wrappedValue))
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }
}
