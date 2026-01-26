import Dependencies
import Foundation

protocol WhoAmI: Sendable {
  func callAsFunction() -> String
}

struct LiveWhoAmI: WhoAmI {
  func callAsFunction() -> String {
    #if os(macOS) || os(Linux)
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/whoami")
      let output = Pipe()
      process.standardOutput = output
      do {
        try process.run()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let value = String(data: data, encoding: .utf8)?
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if let value, !value.isEmpty {
          return value
        }
      } catch {
        // Fall back to the system username.
      }
    #endif
    let fallback = NSUserName()
    return fallback.isEmpty ? "unknown" : fallback
  }
}

struct TestWhoAmI: WhoAmI {
  var value: String

  init(_ value: String = "blob") {
    self.value = value
  }

  func callAsFunction() -> String {
    value
  }
}

enum WhoAmIKey: DependencyKey {
  static var liveValue: any WhoAmI { LiveWhoAmI() }
  static var testValue: any WhoAmI { TestWhoAmI() }
}

extension DependencyValues {
  var whoAmI: any WhoAmI {
    get { self[WhoAmIKey.self] }
    set { self[WhoAmIKey.self] = newValue }
  }
}
