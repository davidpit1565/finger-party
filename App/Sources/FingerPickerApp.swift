import SwiftUI

@main
struct FingerPickerApp: App {
    @State private var model = TouchSessionModel.makeLive()

    var body: some Scene {
        WindowGroup {
            PlayScreen(model: model)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
