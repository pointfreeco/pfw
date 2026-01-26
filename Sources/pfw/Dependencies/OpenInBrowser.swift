import ConcurrencyExtras
import CustomDump
import Dependencies
import Foundation
import XCTestDynamicOverlay

protocol OpenInBrowser: Sendable {
  func callAsFunction(_ url: URL) throws
}

struct LiveOpenInBrowser: OpenInBrowser {
  func callAsFunction(_ url: URL) throws {
    #if os(macOS)
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
      process.arguments = [url.absoluteString]
      try process.run()
    #elseif os(Linux)
      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/xdg-open")
      process.arguments = [url.absoluteString]
      try process.run()
    #else
      print("Please open this URL in your browser: \(url.absoluteString)")
    #endif
  }
}

final class MockOpenInBrowser: OpenInBrowser, @unchecked Sendable {
  let openedURLs = LockIsolated<[URL]>([])

  func callAsFunction(_ url: URL) throws {
    openedURLs.withValue { $0.append(url) }
  }

  @discardableResult
  func assertOpenedURLs(
    _ expected: [URL],
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) -> Bool {
    let actual = openedURLs.withValue { $0 }
    guard actual == expected else {
      expectNoDifference(
        actual,
        expected,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      return false
    }
    openedURLs.withValue { urls in
      urls.removeAll()
    }
    return true
  }
}

enum OpenInBrowserKey: DependencyKey {
  static var liveValue: any OpenInBrowser { LiveOpenInBrowser() }
  static var testValue: any OpenInBrowser { MockOpenInBrowser() }
}

extension DependencyValues {
  var openInBrowser: any OpenInBrowser {
    get { self[OpenInBrowserKey.self] }
    set { self[OpenInBrowserKey.self] = newValue }
  }
}
