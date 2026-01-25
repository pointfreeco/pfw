import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @Suite struct LoginTests {
    @Dependency(\.fileSystem) var fileSystem
    @Dependency(\.openInBrowser) var openInBrowser
    var mockOpenInBrowser: MockOpenInBrowser {
      openInBrowser as! MockOpenInBrowser
    }
    var inMemoryFileSystem: InMemoryFileSystem {
      fileSystem as! InMemoryFileSystem
    }

    @Test(
      .dependencies {
        $0.auth = InMemoryAuth(
          redirectURL: URL(string: "http://localhost:1234/callback"),
          token: "deadbeef"
        )
      }
    )
    func login() async throws {
      try await assertCommand(["login"]) {
        """
        Open this URL to log in and approve access:
        http://localhost:8080/account/the-way/login?whoami=brandon&machine=00000000-0000-0000-0000-000000000000&redirect=http://localhost:1234/callback

        Waiting for browser redirect...
        Saved token to /Users/blob/.pfw/token.
        """
      }
      mockOpenInBrowser.assertOpenedURLs([
        URL(
          string:
            "http://localhost:8080/account/the-way/login?whoami=brandon&machine=00000000-0000-0000-0000-000000000000&redirect=http://localhost:1234/callback"
        )!
      ])
      #expect(
        try String(
          decoding: fileSystem.data(at: URL(filePath: "/Users/blob/.pfw/token")),
          as: UTF8.self
        ) == "deadbeef"
      )
      #expect(
        try String(
          decoding: fileSystem.data(at: URL(filePath: "/Users/blob/.pfw/machine")),
          as: UTF8.self
        ) == "00000000-0000-0000-0000-000000000000"
      )
    }
  }
}
