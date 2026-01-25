import ConcurrencyExtras
import Dependencies
import Foundation
import ZIPFoundation

protocol FileSystem: Sendable {
  var homeDirectoryForCurrentUser: URL { get }
  static var temporaryDirectory: URL { get }
  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]?
  ) throws
  func removeItem(at url: URL) throws
  func fileExists(atPath path: String) -> Bool
  func write(_ data: Data, to url: URL) throws
  func data(at url: URL) throws -> Data
  func unzipItem(
    at sourceURL: URL,
    to destinationURL: URL,
    skipCRC32: Bool,
    allowUncontainedSymlinks: Bool,
    progress: Progress?,
    pathEncoding: String.Encoding?
  ) throws
}

extension FileSystem {
  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool
  ) throws {
    try createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: nil)
  }

  func unzipItem(at sourceURL: URL, to destinationURL: URL) throws {
    try unzipItem(
      at: sourceURL,
      to: destinationURL,
      skipCRC32: false,
      allowUncontainedSymlinks: false,
      progress: nil,
      pathEncoding: nil
    )
  }
}

extension FileManager: FileSystem {
  static var temporaryDirectory: URL {
    URL.temporaryDirectory
  }

  func write(_ data: Data, to url: URL) throws {
    try data.write(to: url)
  }

  func data(at url: URL) throws -> Data {
    try Data(contentsOf: url)
  }
}

final class InMemoryFileSystem: FileSystem {
  enum Error: Swift.Error, Equatable {
    case directoryNotFound(String)
    case fileNotFound(String)
    case fileExists(String)
    case notDirectory(String)
    case isDirectory(String)
  }

  struct State {
    var files: [String: Data]
    var directories: Set<String>
    var homeDirectoryForCurrentUser: URL
  }

  let state: LockIsolated<State>

  init(
    homeDirectoryForCurrentUser: URL = URL(fileURLWithPath: "/Users/blob"),
    files: [String: Data] = [:],
    directories: Set<String> = []
  ) {
    let state = State(
      files: files,
      directories: directories,
      homeDirectoryForCurrentUser: homeDirectoryForCurrentUser
    )
    self.state = LockIsolated(state)
    self.state.withValue {
      _ = $0.directories.insert(normalize(homeDirectoryForCurrentUser))
    }
  }

  var filePaths: Set<String> {
    state.withValue { Set($0.files.keys) }
  }

  func setFile(_ data: Data = Data(), atPath path: String) {
    state.withValue { $0.files[normalize(path)] = data }
  }

  func createDirectory(
    at url: URL,
    withIntermediateDirectories createIntermediates: Bool,
    attributes: [FileAttributeKey: Any]?
  ) throws {
    let path = normalize(url)
    try state.withValue { state in
      guard state.files[path] == nil else {
        throw Error.fileExists(path)
      }

      if createIntermediates {
        for directory in pathPrefixes(path) {
          guard state.files[directory] == nil else {
            throw Error.notDirectory(directory)
          }
          state.directories.insert(directory)
        }
      } else {
        let parent = normalize((path as NSString).deletingLastPathComponent)
        guard state.directories.contains(parent) else {
          throw Error.directoryNotFound(parent)
        }
        state.directories.insert(path)
      }
    }
  }

  func removeItem(at url: URL) throws {
    let path = normalize(url)
    try state.withValue { state in
      guard state.files[path] != nil || state.directories.contains(path) else {
        throw Error.fileNotFound(path)
      }
      state.files.removeValue(forKey: path)
      state.directories.remove(path)

      let prefix = path.hasSuffix("/") ? path : path + "/"
      state.files = state.files.filter { key, _ in
        !key.hasPrefix(prefix)
      }
      state.directories = state.directories.filter { directory in
        !directory.hasPrefix(prefix)
      }
    }
  }

  func fileExists(atPath path: String) -> Bool {
    let normalizedPath = normalize(path)
    return state.withValue { state in
      state.files[normalizedPath] != nil || state.directories.contains(normalizedPath)
    }
  }

  func unzipItem(
    at sourceURL: URL,
    to destinationURL: URL,
    skipCRC32: Bool,
    allowUncontainedSymlinks: Bool,
    progress: Progress?,
    pathEncoding: String.Encoding?
  ) throws {
    let archiveData = try data(at: sourceURL)
    let files = try JSONDecoder().decode([URL: Data].self, from: archiveData)

    for (sourcePath, contents) in files {
      let relativePath = sourcePath.path.hasPrefix("/")
        ? String(sourcePath.path.dropFirst())
        : sourcePath.path
      let destination = destinationURL.appendingPathComponent(relativePath)
      let parent = destination.deletingLastPathComponent()
      try createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
      try write(contents, to: destination)
    }
  }

  var homeDirectoryForCurrentUser: URL {
    state.withValue { $0.homeDirectoryForCurrentUser }
  }

  static var temporaryDirectory: URL {
    URL(fileURLWithPath: "/tmp", isDirectory: true)
  }

  func write(_ data: Data, to url: URL) throws {
    let path = normalize(url)
    let directory = normalize(url.deletingLastPathComponent())
    try state.withValue { state in
      guard state.directories.contains(directory) else {
        throw Error.directoryNotFound(directory)
      }
      guard !state.directories.contains(path) else {
        throw Error.isDirectory(path)
      }
      state.files[path] = data
    }
  }

  func data(at url: URL) throws -> Data {
    let path = normalize(url)
    return try state.withValue { state in
      guard !state.directories.contains(path) else {
        throw Error.isDirectory(path)
      }
      guard let data = state.files[path] else {
        throw Error.fileNotFound(path)
      }
      return data
    }
  }
}

extension InMemoryFileSystem: CustomStringConvertible {
  var description: String {
    state.withValue { state in
      let root = FileNode(name: "/")
      for directory in state.directories {
        insert(path: directory, into: root, data: nil)
      }
      for (path, data) in state.files {
        insert(path: path, into: root, data: data)
      }
      var lines: [String] = []
      for child in root.children.keys.sorted() {
        if let childNode = root.children[child] {
          render(node: childNode, into: &lines, indent: "")
        }
      }
      return lines.joined(separator: "\n")
    }
  }
}

private final class FileNode {
  let name: String
  var children: [String: FileNode] = [:]
  var data: Data?

  init(name: String, data: Data? = nil) {
    self.name = name
    self.data = data
  }
}

private func insert(path: String, into root: FileNode, data: Data?) {
  let components = (path as NSString).pathComponents
  guard !components.isEmpty else { return }
  var current = root
  for component in components {
    if component == "/" { continue }
    let node = current.children[component] ?? FileNode(name: component)
    current.children[component] = node
    current = node
  }
  if let data {
    current.data = data
  }
}

private func render(node: FileNode, into lines: inout [String], indent: String) {
  if node.data == nil {
    lines.append("\(indent)\(node.name)/")
  } else {
    let suffix = fileSummary(data: node.data!)
    lines.append("\(indent)\(node.name) \(suffix)")
  }
  let nextIndent = indent + "  "
  for child in node.children.keys.sorted() {
    if let childNode = node.children[child] {
      render(node: childNode, into: &lines, indent: nextIndent)
    }
  }
}

private func fileSummary(data: Data) -> String {
  if data.count < 50, let string = String(data: data, encoding: .utf8) {
    let sanitized = string
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\r", with: "\\r")
      .replacingOccurrences(of: "\t", with: "\\t")
    return "\"\(sanitized)\""
  }
  return "(\(data.count) bytes)"
}

enum FileSystemKey: DependencyKey {
  static let liveValue: any FileSystem = FileManager.default
  static let testValue: any FileSystem = InMemoryFileSystem()
}

extension DependencyValues {
  var fileSystem: any FileSystem {
    get { self[FileSystemKey.self] }
    set { self[FileSystemKey.self] = newValue }
  }
}

private func normalize(_ url: URL) -> String {
  normalize(url.path)
}

private func normalize(_ path: String) -> String {
  let standardized = (path as NSString).standardizingPath
  if standardized == "/" {
    return standardized
  }
  return standardized.hasSuffix("/") ? String(standardized.dropLast()) : standardized
}

private func pathPrefixes(_ path: String) -> [String] {
  let components = (path as NSString).pathComponents
  guard !components.isEmpty else { return [] }
  var current = ""
  var prefixes: [String] = []
  for component in components {
    if component == "/" {
      current = "/"
    } else if current == "/" {
      current += component
    } else if current.isEmpty {
      current = component
    } else {
      current += "/" + component
    }
    prefixes.append(current)
  }
  return prefixes
}
