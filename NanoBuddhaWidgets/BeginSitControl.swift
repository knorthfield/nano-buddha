import SwiftUI
import WidgetKit

/// Control Centre button that opens the app and begins a sit.
struct BeginSitControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.krisnorthfield.NanoBuddha.begin") {
            ControlWidgetButton(action: BeginSitIntent()) {
                Label("Begin sit", systemImage: "figure.mind.and.body")
            }
        }
        .displayName("Begin sit")
        .description("Start a sit in Nano Buddha.")
    }
}
