import SwiftUI

/// Minus, the intended duration, plus: one minute either way. Sized per platform.
struct NudgeRow: View {
    @Environment(Store.self) private var store
    #if os(tvOS)
    private let spacing = 40.0, iconSize: CGFloat? = 40, font = Font.largeTitle
    #elseif os(watchOS)
    private let spacing = 12.0, iconSize: CGFloat? = nil, font = Font.title3
    #else
    private let spacing = 24.0, iconSize: CGFloat? = 24, font = Font.title
    #endif

    var body: some View {
        HStack(spacing: spacing) {
            Button { store.nudge(by: -60) } label: { Image(systemName: "minus").frame(width: iconSize, height: iconSize) }
                .accessibilityLabel("One minute less")
                .disabled(store.intendedSeconds <= 60)
            Text(store.intendedTimeText)
                .font(font)
                .monospacedDigit()
            Button { store.nudge(by: 60) } label: { Image(systemName: "plus").frame(width: iconSize, height: iconSize) }
                .accessibilityLabel("One minute more")
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}
