import ArgumentParser
import Dependencies
import Foundation

struct Status: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Show current login and install status."
  )

  func run() throws {
    @Dependency(\.fileSystem) var fileSystem

    let tokenExists = fileSystem.fileExists(atPath: tokenURL.path)
    let dataExists = fileSystem.fileExists(atPath: pfwDirectoryURL.path)

    print("Logged in: \(tokenExists ? "yes" : "no")")
    print("Token path: \(tokenURL.path)")
    print("Data directory: \(pfwDirectoryURL.path)")
    print("Data directory exists: \(dataExists ? "yes" : "no")")
  }
}
