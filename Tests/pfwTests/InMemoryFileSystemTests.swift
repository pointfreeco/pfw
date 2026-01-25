import InlineSnapshotTesting
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing
@testable import pfw

extension BaseSuite {
  @Suite(
    .dependencies {
      $0.fileSystem = InMemoryFileSystem(homeDirectoryForCurrentUser: URL(fileURLWithPath: "/root"))
    }
  )
  struct InMemoryFileSystemTests {
    var fileSystem: InMemoryFileSystem {
      @Dependency(\.fileSystem) var fileSystem
      return fileSystem as! InMemoryFileSystem
    }

    @Test func createDirectoryMissingParentWithoutIntermediatesThrows() throws {
      let target = URL(fileURLWithPath: "/root/a/b", isDirectory: true)

      #expect(throws: InMemoryFileSystem.Error.directoryNotFound("/root/a")) {
        try fileSystem.createDirectory(
          at: target,
          withIntermediateDirectories: false,
          attributes: nil
        )
      }
    }

    @Test func createDirectoryWithIntermediatesCreatesAll() throws {
      let target = URL(fileURLWithPath: "/root/a/b", isDirectory: true)
      let parent = URL(fileURLWithPath: "/root/a", isDirectory: true)

      try fileSystem.createDirectory(
        at: target,
        withIntermediateDirectories: true,
        attributes: nil
      )

      #expect(fileSystem.fileExists(atPath: parent.path))
      #expect(fileSystem.fileExists(atPath: target.path))
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          a/
            b/
        """
      }
    }

    @Test func createDirectoryFailsWhenPathIsFile() throws {
      let fileURL = URL(fileURLWithPath: "/root/file")
      fileSystem.setFile(Data("data".utf8), atPath: fileURL.path)

      #expect(throws: InMemoryFileSystem.Error.fileExists(fileURL.path)) {
        try fileSystem.createDirectory(
          at: fileURL,
          withIntermediateDirectories: true,
          attributes: nil
        )
      }
    }

    @Test func createDirectoryFailsWhenIntermediateIsFile() throws {
      let parentFile = URL(fileURLWithPath: "/root/a")
      let target = URL(fileURLWithPath: "/root/a/b", isDirectory: true)
      fileSystem.setFile(Data("data".utf8), atPath: parentFile.path)

      #expect(throws: InMemoryFileSystem.Error.notDirectory(parentFile.path)) {
        try fileSystem.createDirectory(
          at: target,
          withIntermediateDirectories: true,
          attributes: nil
        )
      }
    }

    @Test func removeItemMissingThrows() throws {
      let missing = URL(fileURLWithPath: "/root/missing")

      #expect(throws: InMemoryFileSystem.Error.fileNotFound(missing.path)) {
        try fileSystem.removeItem(at: missing)
      }
    }

    @Test func removeItemRemovesDirectoryContents() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)
      let file = directory.appendingPathComponent("file")

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      try fileSystem.write(Data("data".utf8), to: file)

      try fileSystem.removeItem(at: directory)

      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
        """
      }
    }

    @Test func writeMissingParentThrows() throws {
      let file = URL(fileURLWithPath: "/root/missing/file")

      #expect(throws: InMemoryFileSystem.Error.directoryNotFound("/root/missing")) {
        try fileSystem.write(Data("data".utf8), to: file)
      }
    }

    @Test func writeToDirectoryThrows() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      #expect(throws: InMemoryFileSystem.Error.isDirectory(directory.path)) {
        try fileSystem.write(Data("data".utf8), to: directory)
      }
    }

    @Test func dataMissingThrows() throws {
      let file = URL(fileURLWithPath: "/root/missing")

      #expect(throws: InMemoryFileSystem.Error.fileNotFound(file.path)) {
        _ = try fileSystem.data(at: file)
      }
    }

    @Test func dataAtDirectoryThrows() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )

      #expect(throws: InMemoryFileSystem.Error.isDirectory(directory.path)) {
        _ = try fileSystem.data(at: directory)
      }
    }

    @Test func fileExistsForFilesAndDirectories() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)
      let file = directory.appendingPathComponent("file")

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      try fileSystem.write(Data("data".utf8), to: file)
      #expect(fileSystem.fileExists(atPath: directory.path))
      #expect(fileSystem.fileExists(atPath: file.path))
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          dir/
            file "data"
        """
      }
    }

    @Test func createSymbolicLinkRequiresParentDirectory() throws {
      let link = URL(fileURLWithPath: "/root/missing/link")
      let destination = URL(fileURLWithPath: "/root/target")

      #expect(throws: InMemoryFileSystem.Error.directoryNotFound("/root/missing")) {
        try fileSystem.createSymbolicLink(at: link, withDestinationURL: destination)
      }
    }

    @Test func createSymbolicLinkFailsWhenPathExists() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)
      let link = directory.appendingPathComponent("link")
      let destination = URL(fileURLWithPath: "/root/target")

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      try fileSystem.write(Data("data".utf8), to: link)

      #expect(throws: InMemoryFileSystem.Error.fileExists(link.path)) {
        try fileSystem.createSymbolicLink(at: link, withDestinationURL: destination)
      }
    }

    @Test func createSymbolicLinkToFileCanReadThroughLink() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)
      let target = directory.appendingPathComponent("target")
      let link = directory.appendingPathComponent("link")

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      try fileSystem.write(Data("payload".utf8), to: target)
      try fileSystem.createSymbolicLink(at: link, withDestinationURL: target)

      #expect(fileSystem.fileExists(atPath: link.path))
      #expect(try String(decoding: fileSystem.data(at: link), as: UTF8.self) == "payload")
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          dir/
            link -> /root/dir/target
            target "payload"
        """
      }
    }

    @Test func removeItemRemovesOnlySymbolicLink() throws {
      let directory = URL(fileURLWithPath: "/root/dir", isDirectory: true)
      let target = directory.appendingPathComponent("target")
      let link = directory.appendingPathComponent("link")

      try fileSystem.createDirectory(
        at: directory,
        withIntermediateDirectories: true,
        attributes: nil
      )
      try fileSystem.write(Data("payload".utf8), to: target)
      try fileSystem.createSymbolicLink(at: link, withDestinationURL: target)

      try fileSystem.removeItem(at: link)

      #expect(!fileSystem.fileExists(atPath: link.path))
      #expect(fileSystem.fileExists(atPath: target.path))
      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          dir/
            target "payload"
        """
      }
    }

    @Test func unzipWritesFilesIntoDestination() throws {
      let destination = URL(fileURLWithPath: "/root/unzipped", isDirectory: true)
      let archiveURL = URL(fileURLWithPath: "/root/archive.zip")
      let files: [URL: Data] = [
        URL(fileURLWithPath: "/a.txt"): Data("alpha".utf8),
        URL(fileURLWithPath: "/nested/b.txt"): Data("beta".utf8),
      ]
      let archiveData = try JSONEncoder().encode(files)
      try fileSystem.createDirectory(
        at: archiveURL.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
      )
      try fileSystem.write(archiveData, to: archiveURL)

      try fileSystem.unzipItem(
        at: archiveURL,
        to: destination,
        skipCRC32: false,
        allowUncontainedSymlinks: false,
        progress: nil,
        pathEncoding: nil
      )

      assertInlineSnapshot(of: fileSystem, as: .description) {
        """
        root/
          archive.zip (69 bytes)
          unzipped/
            a.txt "alpha"
            nested/
              b.txt "beta"
        """
      }
    }

    @Test func unzipMissingSourceThrows() throws {
      let archiveURL = URL(fileURLWithPath: "/root/missing.json")
      let destination = URL(fileURLWithPath: "/root/unzipped", isDirectory: true)

      #expect(throws: InMemoryFileSystem.Error.fileNotFound(archiveURL.path)) {
        try fileSystem.unzipItem(
          at: archiveURL,
          to: destination,
          skipCRC32: false,
          allowUncontainedSymlinks: false,
          progress: nil,
          pathEncoding: nil
        )
      }
    }
  }
}
