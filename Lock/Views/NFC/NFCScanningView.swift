import SwiftUI

struct NFCScanningView: View {
    let title: String

    var body: some View {
        VStack(spacing: 28) {
            NFCAnimation()
            Text(title)
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}
