import SwiftUI

/// The one full-width action on each screen: Begin, End, Done. Tinted glass, same size everywhere.
struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.glass(.clear.tint(Color("GlassTint"))))
        #if os(watchOS)
        .padding(.horizontal, 8)
        #else
        .padding(.horizontal, 48)
        .frame(maxWidth: 480)
        #endif
    }
}
