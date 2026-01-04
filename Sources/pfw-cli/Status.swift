import ArgumentParser
import Foundation

struct Status: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Show current login and install status."
  )

  func run() throws {
    let fileManager = FileManager.default
    let tokenExists = fileManager.fileExists(atPath: tokenURL.path)
    let dataExists = fileManager.fileExists(atPath: pfwDirectoryURL.path)

    print("Logged in: \(tokenExists ? "yes" : "no")")
    print("Token path: \(tokenURL.path)")
    print("Data directory: \(pfwDirectoryURL.path)")
    print("Data directory exists: \(dataExists ? "yes" : "no")")

    let codexPath = Install.Tool.codex.defaultInstallPath.path
    let claudePath = Install.Tool.claude.defaultInstallPath.path
    print("Default install path (codex): \(codexPath)")
    print("Default install path (claude): \(claudePath)")
  }
}
