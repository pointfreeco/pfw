import ConcurrencyExtras
import CustomDump
import Foundation
import Testing

@testable import pfw

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
    openedURLs.withValue { $0.removeAll() }
    return true
  }

  func skipAssertions() {
    openedURLs.withValue { $0.removeAll() }
  }

  deinit {
    let shouldRecord = openedURLs.withValue { !$0.isEmpty }
    guard shouldRecord else { return }
    Issue.record("MockOpenInBrowser was not asserted before deallocation.")
  }
}
