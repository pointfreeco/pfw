import ArgumentParser
import Foundation

struct Logout: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Log out and remove the stored token."
  )

  @Flag(help: "Remove all stored data, including downloaded skills.")
  var clean = false

  func run() throws {
    let fileManager = FileManager.default
    if clean {
      if fileManager.fileExists(atPath: pfwDirectoryURL.path) {
        try fileManager.removeItem(at: pfwDirectoryURL)
        print("Removed data at \(pfwDirectoryURL.path).")
      } else {
        print("No data found.")
      }
      return
    }

    if fileManager.fileExists(atPath: tokenURL.path) {
      try fileManager.removeItem(at: tokenURL)
      print("Removed token at \(tokenURL.path).")
      return
    }
    print("No token found.")
  }
}
