import ArgumentParser
import Foundation
import InlineSnapshotTesting
import Testing

@testable import pfw

#if canImport(Darwin)
  import Darwin
#else
  @preconcurrency import Glibc
#endif

func assertCommand(
  _ arguments: [String],
  stdout expected: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) async throws {
  let output = try await withCapturedStdout {
    var command = try PFW.parseAsRoot(arguments)
    if var command = command as? AsyncParsableCommand {
      try await command.run()
    } else {
      try command.run()
    }
  }
  assertInlineSnapshot(
    of: output,
    as: .lines,
    matches: expected,
    fileID: fileID,
    file: file,
    line: line,
    column: column
  )
}

func assertCommandThrows(
  _ arguments: [String],
  error: (() -> String)? = nil,
  fileID: StaticString = #fileID,
  file: StaticString = #filePath,
  line: UInt = #line,
  column: UInt = #column
) async {
  var thrownError: Error?
  do {
    var command = try PFW.parseAsRoot(arguments)
    if var command = command as? AsyncParsableCommand {
      try await command.run()
    } else {
      try command.run()
    }
  } catch {
    thrownError = error
  }

  guard let thrownError else {
    Issue
      .record(
        "Expected command to throw.",
        sourceLocation: SourceLocation.init(
          fileID: String(describing: fileID),
          filePath: String(describing: file),
          line: Int(line),
          column: Int(column)
        )
      )
    return
  }

  assertInlineSnapshot(
    of: PFW.message(for: thrownError),
    as: .lines,
    matches: error,
    fileID: fileID,
    file: file,
    line: line,
    column: column
  )
}

// TODO: Explore a dependency alternative to this.
private func withCapturedStdout(
  _ body: () async throws -> Void
) async rethrows -> String {
  let pipe = Pipe()
  let original = dup(STDOUT_FILENO)
  fflush(nil)
  dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

  try await body()

  fflush(nil)
  dup2(original, STDOUT_FILENO)
  close(original)
  pipe.fileHandleForWriting.closeFile()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
