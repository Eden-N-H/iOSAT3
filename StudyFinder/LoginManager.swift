import Foundation
import SwiftUI
import Combine

class LoginManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""

    private let usernameKey = "savedUsername"
    private let passwordKey = "savedPassword"
    private let emailKey = "savedEmail"

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
    }

    func login(username: String, password: String) {
        let savedUsername = UserDefaults.standard.string(forKey: usernameKey)
        let savedPassword = UserDefaults.standard.string(forKey: passwordKey)

        errorMessage = ""
        successMessage = ""

        if username.isEmpty || password.isEmpty {
            errorMessage = "Please enter both username and password."
            return
        }

        if username == savedUsername && password == savedPassword {
            UserDefaults.standard.set(true, forKey: "isLoggedIn")
            isLoggedIn = true
            errorMessage = ""
        } else {
            errorMessage = "Incorrect username or password."
        }
    }

    func createAccount(username: String, email: String, password: String) -> Bool {
        errorMessage = ""
        successMessage = ""

        if username.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "Please fill in all fields."
            return false
        }

        if !email.contains("@") {
            errorMessage = "Please enter a valid email address."
            return false
        }

        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }

        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(password, forKey: passwordKey)

        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        isLoggedIn = false

        successMessage = "Account created successfully. Please login."
        errorMessage = ""

        return true
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        isLoggedIn = false
    }
}
