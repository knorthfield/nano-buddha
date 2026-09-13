import SwiftUI
import WidgetKit

/// The watch complication: the same `SitWidget` as the iPhone, in the accessory families only.
@main
struct NanoBuddhaWatchWidgets: WidgetBundle {
    var body: some Widget {
        SitWidget()
    }
}
