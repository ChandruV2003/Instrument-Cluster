import SwiftUI

struct ChipView: View {
    let icon: String
    let text: String

    var body: some View {
        Label {
            Text(text).font(.footnote.monospacedDigit())
        } icon: {
            Image(systemName: icon)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
