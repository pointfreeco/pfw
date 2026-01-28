import ArgumentParser
import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @Suite(
    .dependencies {
      $0.auth = InMemoryAuth(
        redirectURL: URL(string: "http://localhost:1234/callback"),
        token: "deadbeef"
      )
      $0.continuousClock = TestClock()
    },
    .snapshots(  // record: .failed
    ),
  )
  @MainActor struct InstallTests {
    @Dependency(\.continuousClock, as: TestClock<Duration>.self) var clock
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem
    @Dependency(\.openInBrowser, as: MockOpenInBrowser.self) var openInBrowser

    @Test func noToolOrPathSpecified() async throws {
      await assertCommandThrows(["install"]) {
        """
        Provide either --tool or --path.
        """
      }
    }

    @Test func bothToolAndPathSpecified() async throws {
      await assertCommandThrows(["install", "--tool", "codex", "--path", "/User/blob/.codex"]) {
        """
        Provide either --tool or --path.
        """
      }
    }

    @Test func loggedOut() async throws {
      await assertCommandThrows(["install", "--tool", "codex"]) {
        """
        No token found. Run `pfw login` first.
        """
      }
    }

    @Test(
      .dependencies { dependencies in
        try save(token: "expired-deadbeef")
        dependencies.pointFreeServer = InMemoryPointFreeServer(
          results: [
            .failure(.notLoggedIn("Token expired")),
            .success(
              .data(
                try [
                  URL(filePath: "/skills/ComposableArchitecture/SKILL.md"): Data(
                    """
                    # Composable Architecture
                    """.utf8
                  )
                ].toData,
                etag: "cafebeef"
              )
            ),
          ]
        )
      }
    )
    func expiredToken() async throws {
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        Users/
          blob/
            .pfw/
              token "expired-deadbeef"
        tmp/
        """
      }
      let task = Task {
        try await assertCommand(["install", "--tool", "codex"]) {
          """
          Authentication failed. Starting login flow...
          Open this URL to log in and approve access:
          http://localhost:8080/account/the-way/login?whoami=blob&machine=00000000-0000-0000-0000-000000000001&redirect=http://localhost:1234/callback

          Waiting for browser redirect...
          Saved token to /Users/blob/.pfw/token.
          Login complete. Retrying install...
          Installed skills for codex into /Users/blob/.codex/skills
          """
        }
      }
      try await Task.sleep(for: .seconds(0.5))
      await clock.run()
      try await task.value
      openInBrowser.assertOpenedURLs([
        URL(
          string:
            "http://localhost:8080/account/the-way/login?whoami=blob&machine=00000000-0000-0000-0000-000000000001&redirect=http://localhost:1234/callback"
        )!
      ])
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        Users/
          blob/
            .codex/
              skills/
                pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
            .pfw/
              machine "00000000-0000-0000-0000-000000000002"
              sha "cafebeef"
              skills/
                ComposableArchitecture/
                  SKILL.md "# Composable Architecture"
              token "deadbeef"
        tmp/
        """
      }
    }

    @Suite(
      .dependencies {
        try await $0.login()
        $0.pointFreeServer = InMemoryPointFreeServer(
          result: .success(
            .data(
              try [
                URL(filePath: "/skills/ComposableArchitecture/SKILL.md"): Data(
                  """
                  # Composable Architecture
                  """.utf8
                ),
                URL(filePath: "/skills/ComposableArchitecture/references/navigation.md"): Data(
                  """
                  # Navigation
                  """.utf8
                ),
                URL(filePath: "/skills/SQLiteData/SKILL.md"): Data(
                  """
                  # SQLiteData
                  """.utf8
                ),
              ].toData,
              etag: "cafebeef"
            )
          )
        )
      }
    )
    @MainActor struct LoggedIn {
      @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

      @Test func codex() async throws {
        try await assertCommand(["install", "--tool", "codex"]) {
          """
          Installed skills for codex into /Users/blob/.codex/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func deletesPreviousPFWDirectories() async throws {
        try fileSystem.createDirectory(
          at: URL(filePath: "/Users/blob/.pfw/skills/ComposableArchitecture"),
          withIntermediateDirectories: true
        )
        try fileSystem.write(
          Data("Old stuff".utf8),
          to: URL(filePath: "/Users/blob/.pfw/skills/ComposableArchitecture/SKILL.md")
        )
        try fileSystem.createDirectory(
          at: URL(filePath: "/Users/blob/.pfw/skills/UnrecognizedSkill"),
          withIntermediateDirectories: true
        )
        try fileSystem.createDirectory(
          at: URL(filePath: "/Users/blob/.codex/skills/"),
          withIntermediateDirectories: true
        )
        try fileSystem.createSymbolicLink(
          at: URL(filePath: "/Users/blob/.codex/skills/pfw-ComposableArchitecture"),
          withDestinationURL: URL(filePath: "/Users/blob/.pfw/skills/ComposableArchitecture")
        )
        try fileSystem.createSymbolicLink(
          at: URL(filePath: "/Users/blob/.codex/skills/pfw-UnrecognizedSkill"),
          withDestinationURL: URL(filePath: "/Users/blob/.pfw/skills/UnrecognizedSkill")
        )
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-UnrecognizedSkill@ -> /Users/blob/.pfw/skills/UnrecognizedSkill
              .pfw/
                machine "00000000-0000-0000-0000-000000000000"
                skills/
                  ComposableArchitecture/
                    SKILL.md "Old stuff"
                  UnrecognizedSkill/
                token "deadbeef"
          tmp/
          """
        }

        try await assertCommand(["install", "--tool", "codex"]) {
          """
          Installed skills for codex into /Users/blob/.codex/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func deletesOldPFWDirectory() async throws {
        try fileSystem.createDirectory(
          at: URL(filePath: "/Users/blob/.codex/skills/the-point-free-way"),
          withIntermediateDirectories: true
        )
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                skills/
                  the-point-free-way/
              .pfw/
                machine "00000000-0000-0000-0000-000000000000"
                token "deadbeef"
          tmp/
          """
        }

        try await assertCommand(["install", "--tool", "codex"]) {
          """
          Installed skills for codex into /Users/blob/.codex/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func claude() async throws {
        try await assertCommand(["install", "--tool", "claude"]) {
          """
          Installed skills for claude into /Users/blob/.claude/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .claude/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func cursor() async throws {
        try await assertCommand(["install", "--tool", "cursor"]) {
          """
          Installed skills for cursor into /Users/blob/.cursor/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .cursor/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func copilot() async throws {
        try await assertCommand(["install", "--tool", "copilot"]) {
          """
          Installed skills for copilot into /Users/blob/.copilot/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .copilot/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func kiro() async throws {
        try await assertCommand(["install", "--tool", "kiro"]) {
          """
          Installed skills for kiro into /Users/blob/.kiro/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .kiro/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func gemini() async throws {
        try await assertCommand(["install", "--tool", "gemini"]) {
          """
          Installed skills for gemini into /Users/blob/.gemini/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .gemini/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func antigravity() async throws {
        try await assertCommand(["install", "--tool", "antigravity"]) {
          """
          Installed skills for antigravity into /Users/blob/.gemini/antigravity/global_skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .gemini/
                antigravity/
                  global_skills/
                    pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                    pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func opencode() async throws {
        try await assertCommand(["install", "--tool", "opencode"]) {
          """
          Installed skills for opencode into /Users/blob/.config/opencode/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .config/
                opencode/
                  skills/
                    pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                    pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func kimi() async throws {
        try await assertCommand(["install", "--tool", "kimi"]) {
          """
          Installed skills for kimi into /Users/blob/.kimi/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .kimi/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func droid() async throws {
        try await assertCommand(["install", "--tool", "droid"]) {
          """
          Installed skills for droid into /Users/blob/.factory/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .factory/
                skills/
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test func tildePath() async throws {
        try await assertCommand(["install", "--path", "~/.codex"]) {
          """
          Installed skills into /Users/blob/.codex
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .codex/
                pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }

      @Test(
        .dependencies {
          try $0.fileSystem.createDirectory(
            at: URL(filePath: "/Users/blob/.copilot/skills"),
            withIntermediateDirectories: true
          )
          try $0.fileSystem.write(
            Data("Hello".utf8),
            to: URL(filePath: "/Users/blob/.copilot/skills/dont-delete.md")
          )
        }
      )
      func customPath() async throws {
        try await assertCommand(["install", "--path", "/Users/blob/.copilot/skills"]) {
          """
          Installed skills into /Users/blob/.copilot/skills
          """
        }
        assertInlineSnapshot(of: fileSystem, as: .description) {
          """
          Users/
            blob/
              .copilot/
                skills/
                  dont-delete.md "Hello"
                  pfw-ComposableArchitecture@ -> /Users/blob/.pfw/skills/ComposableArchitecture
                  pfw-SQLiteData@ -> /Users/blob/.pfw/skills/SQLiteData
              .pfw/
                machine "00000000-0000-0000-0000-000000000001"
                sha "cafebeef"
                skills/
                  ComposableArchitecture/
                    SKILL.md "# Composable Architecture"
                    references/
                      navigation.md "# Navigation"
                  SQLiteData/
                    SKILL.md "# SQLiteData"
                token "deadbeef"
          tmp/
          """
        }
      }
    }
  }
}

extension [URL: Data] {
  var toData: Data {
    get throws {
      try JSONEncoder().encode(self)
    }
  }
}
