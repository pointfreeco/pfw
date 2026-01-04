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
      if fileManager.fileExists(atPath: directoryURL.path) {
        try fileManager.removeItem(at: directoryURL)
        print("Removed data at \(directoryURL.path).")
      } else {
        print("No data found.")
      }
      return
    }

    if fileManager.fileExists(atPath: storeURL.path) {
      try fileManager.removeItem(at: storeURL)
      print("Removed token at \(storeURL.path).")
      return
    }
    print("No token found.")
  }
}
