import SwiftUI

@main
struct StudyFinderApp: App {
    @StateObject private var loginManager = LoginManager()

    var body: some Scene {
        WindowGroup {
            if loginManager.isLoggedIn {
                HomeView()
                    .environmentObject(loginManager)
            } else {
                LoginView()
                    .environmentObject(loginManager)
            }
        }
    }
}
