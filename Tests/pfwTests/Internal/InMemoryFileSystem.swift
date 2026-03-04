import ConcurrencyExtras
import Foundation

@testable import pfw

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
    var symbolicLinks: [String: String]
    var homeDirectoryForCurrentUser: URL
    var currentDirectoryPath: String
  }

  let state: LockIsolated<State>

  init(
    homeDirectoryForCurrentUser: URL = URL(fileURLWithPath: "/Users/blob"),
    currentDirectoryPath: String = "/Users/blob/project",
    files: [String: Data] = [:],
    directories: Set<String> = []
  ) {
    let state = State(
      files: files,
      directories: directories,
      symbolicLinks: [:],
      homeDirectoryForCurrentUser: homeDirectoryForCurrentUser,
      currentDirectoryPath: currentDirectoryPath
    )
    self.state = LockIsolated(state)
    self.state.withValue {
      _ = $0.directories.insert(normalize(homeDirectoryForCurrentUser))
      _ = $0.directories.insert(normalize(Self.temporaryDirectory))
    }
  }

  var filePaths: Set<String> {
    state.withValue { Set($0.files.keys) }
  }

  func setFile(_ data: Data = Data(), atPath path: String) {
    state.withValue { $0.files[normalize(path)] = data }
  }

  func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
    let path = normalize(url)
    try state.withValue { state in
      guard state.files[path] == nil, state.symbolicLinks[path] == nil else {
        throw Error.fileExists(path)
      }

      if createIntermediates {
        for directory in pathPrefixes(path) {
          guard state.files[directory] == nil, state.symbolicLinks[directory] == nil else {
            throw Error.notDirectory(directory)
          }
          state.directories.insert(directory)
        }
      } else {
        let parent = normalize(url.deletingLastPathComponent())
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
      guard
        state.files[path] != nil
          || state.directories.contains(path)
          || state.symbolicLinks[path] != nil
      else {
        throw Error.fileNotFound(path)
      }
      state.files.removeValue(forKey: path)
      state.directories.remove(path)
      state.symbolicLinks.removeValue(forKey: path)

      let prefix = path.hasSuffix("/") ? path : path + "/"
      state.files = state.files.filter { key, _ in
        !key.hasPrefix(prefix)
      }
      state.directories = state.directories.filter { directory in
        !directory.hasPrefix(prefix)
      }
      state.symbolicLinks = state.symbolicLinks.filter { linkPath, _ in
        !linkPath.hasPrefix(prefix)
      }
    }
  }

  func fileExists(atPath path: String) -> Bool {
    let normalizedPath = normalize(path)
    return state.withValue { state in
      state.files[normalizedPath] != nil
        || state.directories.contains(normalizedPath)
        || state.symbolicLinks[normalizedPath] != nil
    }
  }

  func unzipItem(
    at sourceURL: URL, to destinationURL: URL
  ) throws {
    let archiveData = try data(at: sourceURL)
    let files = try JSONDecoder().decode([URL: Data].self, from: archiveData)

    for (sourcePath, contents) in files {
      let relativePath =
        sourcePath.path.hasPrefix("/")
        ? String(sourcePath.path.dropFirst())
        : sourcePath.path
      let destination = destinationURL.appendingPathComponent(relativePath)
      let parent = destination.deletingLastPathComponent()
      try createDirectory(at: parent, withIntermediateDirectories: true)
      try write(contents, to: destination)
    }
  }

  var homeDirectoryForCurrentUser: URL {
    state.withValue { $0.homeDirectoryForCurrentUser }
  }

  var currentDirectoryPath: String {
    state.withValue { $0.currentDirectoryPath }
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
      guard state.symbolicLinks[path] == nil else {
        throw Error.fileExists(path)
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
      if let linkedPath = state.symbolicLinks[path] {
        guard !state.directories.contains(linkedPath) else {
          throw Error.isDirectory(linkedPath)
        }
        if let data = state.files[linkedPath] {
          return data
        } else {
          throw Error.fileNotFound(linkedPath)
        }
      }
      guard let data = state.files[path] else {
        throw Error.fileNotFound(path)
      }
      return data
    }
  }

  func createSymbolicLink(at url: URL, withDestinationURL destURL: URL) throws {
    let linkPath = normalize(url)
    let destinationPath = normalize(destURL)
    let parent = normalize(url.deletingLastPathComponent())
    try state.withValue { state in
      guard state.directories.contains(parent) else {
        throw Error.directoryNotFound(parent)
      }
      guard state.files[linkPath] == nil,
        state.directories.contains(linkPath) == false,
        state.symbolicLinks[linkPath] == nil
      else {
        throw Error.fileExists(linkPath)
      }
      state.symbolicLinks[linkPath] = destinationPath
    }
  }

  func moveItem(at srcURL: URL, to dstURL: URL) throws {
    let sourcePath = normalize(srcURL)
    let destinationPath = normalize(dstURL)
    let destinationParent = normalize(dstURL.deletingLastPathComponent())
    try state.withValue { state in
      guard state.directories.contains(destinationParent) else {
        throw Error.directoryNotFound(destinationParent)
      }
      guard state.files[destinationPath] == nil,
        state.directories.contains(destinationPath) == false,
        state.symbolicLinks[destinationPath] == nil
      else {
        throw Error.fileExists(destinationPath)
      }

      if let data = state.files.removeValue(forKey: sourcePath) {
        state.files[destinationPath] = data
        return
      }
      if let link = state.symbolicLinks.removeValue(forKey: sourcePath) {
        state.symbolicLinks[destinationPath] = link
        return
      }
      guard state.directories.contains(sourcePath) else {
        throw Error.fileNotFound(sourcePath)
      }

      state.directories.remove(sourcePath)
      state.directories.insert(destinationPath)

      let sourcePrefix = sourcePath.hasSuffix("/") ? sourcePath : sourcePath + "/"
      let destinationPrefix =
        destinationPath.hasSuffix("/") ? destinationPath : destinationPath + "/"

      var updatedDirectories: Set<String> = []
      for directory in state.directories {
        if directory.hasPrefix(sourcePrefix) {
          let suffix = directory.dropFirst(sourcePrefix.count)
          updatedDirectories.insert(destinationPrefix + suffix)
        } else {
          updatedDirectories.insert(directory)
        }
      }
      state.directories = updatedDirectories

      var updatedFiles: [String: Data] = [:]
      for (path, data) in state.files {
        if path.hasPrefix(sourcePrefix) {
          let suffix = path.dropFirst(sourcePrefix.count)
          updatedFiles[destinationPrefix + suffix] = data
        } else {
          updatedFiles[path] = data
        }
      }
      state.files = updatedFiles

      var updatedLinks: [String: String] = [:]
      for (path, target) in state.symbolicLinks {
        if path.hasPrefix(sourcePrefix) {
          let suffix = path.dropFirst(sourcePrefix.count)
          updatedLinks[destinationPrefix + suffix] = target
        } else {
          updatedLinks[path] = target
        }
      }
      state.symbolicLinks = updatedLinks
    }
  }

  func contentsOfDirectory(at url: URL) throws -> [URL] {
    let path = normalize(url)
    return try state.withValue { state in
      guard state.directories.contains(path) else {
        if state.files[path] != nil || state.symbolicLinks[path] != nil {
          throw Error.notDirectory(path)
        }
        throw Error.directoryNotFound(path)
      }

      let prefix = path.hasSuffix("/") ? path : path + "/"
      var children: Set<String> = []

      for directory in state.directories {
        if directory.hasPrefix(prefix) {
          let remainder = directory.dropFirst(prefix.count)
          if let next = remainder.split(separator: "/").first, !next.isEmpty {
            children.insert(String(next))
          }
        }
      }

      for file in state.files.keys {
        if file.hasPrefix(prefix) {
          let remainder = file.dropFirst(prefix.count)
          if let next = remainder.split(separator: "/").first, !next.isEmpty {
            children.insert(String(next))
          }
        }
      }

      for link in state.symbolicLinks.keys {
        if link.hasPrefix(prefix) {
          let remainder = link.dropFirst(prefix.count)
          if let next = remainder.split(separator: "/").first, !next.isEmpty {
            children.insert(String(next))
          }
        }
      }

      return children.sorted().map { url.appendingPathComponent($0) }
    }
  }

  func copyItem(at srcURL: URL, to dstURL: URL) throws {
    let sourcePath = normalize(srcURL)
    let destinationPath = normalize(dstURL)
    let destinationParent = normalize(dstURL.deletingLastPathComponent())
    try state.withValue { state in
      guard state.directories.contains(destinationParent) else {
        throw Error.directoryNotFound(destinationParent)
      }
      guard state.files[destinationPath] == nil,
        state.directories.contains(destinationPath) == false,
        state.symbolicLinks[destinationPath] == nil
      else {
        throw Error.fileExists(destinationPath)
      }

      guard state.directories.contains(sourcePath) else {
        throw Error.fileNotFound(sourcePath)
      }

      state.directories.insert(destinationPath)

      let sourcePrefix = sourcePath.hasSuffix("/") ? sourcePath : sourcePath + "/"
      let destinationPrefix =
        destinationPath.hasSuffix("/") ? destinationPath : destinationPath + "/"

      for directory in state.directories {
        if directory.hasPrefix(sourcePrefix) {
          let suffix = directory.dropFirst(sourcePrefix.count)
          state.directories.insert(destinationPrefix + suffix)
        }
      }

      for (path, data) in state.files {
        if path.hasPrefix(sourcePrefix) {
          let suffix = path.dropFirst(sourcePrefix.count)
          state.files[destinationPrefix + suffix] = data
        }
      }
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
      for (path, destination) in state.symbolicLinks {
        insert(path: path, into: root, link: destination)
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
  var linkDestination: String?

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

private func insert(path: String, into root: FileNode, link: String) {
  let components = (path as NSString).pathComponents
  guard !components.isEmpty else { return }
  var current = root
  for component in components {
    if component == "/" { continue }
    let node = current.children[component] ?? FileNode(name: component)
    current.children[component] = node
    current = node
  }
  current.linkDestination = link
}

private func render(node: FileNode, into lines: inout [String], indent: String) {
  if let linkDestination = node.linkDestination {
    lines.append("\(indent)\(node.name)@ -> \(linkDestination)")
  } else if node.data == nil {
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
    let sanitized =
      string
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\r", with: "\\r")
      .replacingOccurrences(of: "\t", with: "\\t")
    return "\"\(sanitized)\""
  }
  return "(\(data.count) bytes)"
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
