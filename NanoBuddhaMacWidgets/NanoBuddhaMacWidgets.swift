import SwiftUI
import WidgetKit

/// The Mac desktop widget: the same `SitWidget` as the iPhone, in the system families only.
@main
struct NanoBuddhaMacWidgets: WidgetBundle {
    var body: some Widget {
        SitWidget()
    }
}
