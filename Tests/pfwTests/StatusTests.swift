import Testing

@testable import pfw

extension BaseSuite {
  @Suite @MainActor struct StatusTests {
    @Test func basics() async throws {
      try await assertCommand(["status"]) {
        """
        Logged in: no
        Token path: /Users/blob/.pfw/token
        Data directory: /Users/blob/.pfw
        Data directory exists: no
        """
      }
    }
  }
}
