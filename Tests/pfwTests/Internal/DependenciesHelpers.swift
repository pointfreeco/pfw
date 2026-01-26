import ArgumentParser
import Dependencies
import Testing

@testable import pfw

extension DependencyValues {
  func login() async throws {
    var command = try #require(try PFW.parseAsRoot(["login"]) as? AsyncParsableCommand)
    try await command.run()
    try #require(openInBrowser as? MockOpenInBrowser).skipAssertions()
  }
}

extension Dependency {
  public init<T>(
    _ keyPath: KeyPath<DependencyValues, T> & Sendable,
    as type: Value.Type,
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
  ) {
    self.init(
      \.[keyPath, as: HashableType(type)],
      fileID: fileID,
      filePath: filePath,
      line: line,
      column: column
    )
  }
}

extension DependencyValues {
  subscript<Member, Other>(
    keyPath: KeyPath<DependencyValues, Member>,
    as type: HashableType<Other>
  ) -> Other {
    self[keyPath: keyPath] as! Other
  }
}

struct HashableType<T>: Hashable {
  let type: T.Type
  init(_ type: T.Type) {
    self.type = type
  }
  static func == (lhs: Self, rhs: Self) -> Bool {
    ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
  }
  func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(type))
  }
}
