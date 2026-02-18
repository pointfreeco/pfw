import Dependencies
import DependenciesTestSupport
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

extension BaseSuite {
  @MainActor
  @Suite
  struct ConfigDirectoryTests {
    @Dependency(\.fileSystem, as: InMemoryFileSystem.self) var fileSystem

    @Test(
      .dependencies {
        $0.fileSystem = InMemoryFileSystem(
          homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
      }
    )
    func configDirUsesPfwHomeWhenPresent() throws {
      try withEnvironment("PFW_HOME", "/root/custom") {
        try withEnvironment("XDG_CONFIG_HOME", "/root/.xdg") {
          try save(token: "deadbeef")
        }
      }
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          custom/
            token "deadbeef"
        tmp/
        """
      }
    }

    @Test(
      .dependencies {
        $0.fileSystem = InMemoryFileSystem(
          homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
      }
    )
    func configDirUsesXdgWhenPresent() throws {
      try withEnvironment("PFW_HOME", nil) {
        try withEnvironment("XDG_CONFIG_HOME", "/root/.xdg") {
          try save(token: "deadbeef")
        }
      }
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          .xdg/
            pfw/
              token "deadbeef"
        tmp/
        """
      }
    }

    @Test(
      .dependencies {
        $0.fileSystem = InMemoryFileSystem(
          homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
      }
    )
    func configDirFallsBackToLegacy() throws {
      try withEnvironment("PFW_HOME", nil) {
        try withEnvironment("XDG_CONFIG_HOME", nil) {
          try save(token: "deadbeef")
        }
      }
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          .pfw/
            token "deadbeef"
        tmp/
        """
      }
    }
  }
}
