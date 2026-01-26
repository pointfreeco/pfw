import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @Suite @MainActor struct LoginTests {
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem
    @Dependency(\.openInBrowser, as: MockOpenInBrowser.self) var openInBrowser

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
        http://localhost:8080/account/the-way/login?whoami=blob&machine=00000000-0000-0000-0000-000000000000&redirect=http://localhost:1234/callback

        Waiting for browser redirect...
        Saved token to /Users/blob/.pfw/token.
        """
      }
      openInBrowser.assertOpenedURLs([
        URL(
          string:
            "http://localhost:8080/account/the-way/login?whoami=blob&machine=00000000-0000-0000-0000-000000000000&redirect=http://localhost:1234/callback"
        )!
      ])
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        Users/
          blob/
            .pfw/
              machine "00000000-0000-0000-0000-000000000000"
              token "deadbeef"
        tmp/
        """
      }
    }
  }
}
