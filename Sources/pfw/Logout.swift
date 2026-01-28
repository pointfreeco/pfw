import ArgumentParser
import Dependencies
import Foundation

struct Logout: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Remove any stored credentials."
  )

  func run() throws {
    @Dependency(\.fileSystem) var fileSystem
    do {
      try fileSystem.removeItem(at: tokenURL)
      print("Logged out")
    } catch {
      print("Already logged out")
    }
  }
}
