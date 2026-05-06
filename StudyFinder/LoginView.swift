import SwiftUI

struct LoginView: View {
    @EnvironmentObject var loginManager: LoginManager

    @State private var username = ""
    @State private var password = ""
    @State private var showCreateAccount = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.25), Color.green.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "book.pages.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.blue)

                        Text("StudySpot Finder")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Find the perfect place to study")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)

                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(12)

                        if !loginManager.errorMessage.isEmpty {
                            Text(loginManager.errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            loginManager.login(username: username, password: password)
                        } label: {
                            Text("Login")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button {
                            loginManager.errorMessage = ""
                            showCreateAccount = true
                        } label: {
                            Text("Create Account")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.75))
                    .cornerRadius(20)
                    .shadow(radius: 8)
                    .padding(.horizontal)
                }
            }
            .navigationDestination(isPresented: $showCreateAccount) {
                CreateAccountView()
            }
        }
    }
}

