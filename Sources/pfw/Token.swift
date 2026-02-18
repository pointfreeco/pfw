import ArgumentParser
import Dependencies
import Foundation

var machineURL: URL {
  pfwDirectoryURL.appendingPathComponent("machine")
}

var tokenURL: URL {
  pfwDirectoryURL.appendingPathComponent("token")
}

var shaURL: URL {
  pfwDirectoryURL.appendingPathComponent("sha")
}

var pfwDirectoryURL: URL {
  pfwDirectoryEnvOverride ?? xdgDirectoryURL ?? defaultPfwDirectoryURL
}

private var defaultPfwDirectoryURL: URL {
  @Dependency(\.fileSystem) var fileSystem
  return fileSystem.homeDirectoryForCurrentUser
    .appendingPathComponent(".pfw", isDirectory: true)
}

private var pfwDirectoryEnvOverride: URL? {
  let pfwHome = ProcessInfo.processInfo.environment["PFW_HOME"]
  if let path = pfwHome?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
    return URL(fileURLWithPath: path, isDirectory: true)
  } else {
    return nil
  }
}

private var xdgDirectoryURL: URL? {
  let xdgConfigDir = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"]
  if let path = xdgConfigDir?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
    return URL(fileURLWithPath: path, isDirectory: true)
      .appendingPathComponent("pfw", isDirectory: true)
  } else {
    return nil
  }
}

func machine() throws -> UUID {
  @Dependency(\.fileSystem) var fileSystem
  @Dependency(\.uuid) var uuid
  try fileSystem.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  if let currentMachineData = try? Data(contentsOf: machineURL),
    let currentMachine = UUID(uuidString: String(decoding: currentMachineData, as: UTF8.self))
  {
    return currentMachine
  } else {
    try? fileSystem.removeItem(at: machineURL)
    let newMachine = uuid()
    try fileSystem.write(Data(newMachine.uuidString.utf8), to: machineURL)
    return newMachine
  }
}

func save(token: String) throws {
  @Dependency(\.fileSystem) var fileSystem
  try fileSystem.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  try fileSystem.write(
    Data(token.trimmingCharacters(in: .whitespacesAndNewlines).utf8),
    to: tokenURL
  )
}

func loadToken() throws -> String {
  @Dependency(\.fileSystem) var fileSystem
  guard fileSystem.fileExists(atPath: tokenURL.path) else {
    throw ValidationError("No token found. Run 'pfw login' first.")
  }
  return try String(decoding: fileSystem.data(at: tokenURL), as: UTF8.self)
}

func loadSHA() -> String? {
  @Dependency(\.fileSystem) var fileSystem
  guard let data = try? fileSystem.data(at: shaURL)
  else {
    return nil
  }
  return String(decoding: data, as: UTF8.self)
    .trimmingCharacters(in: .whitespacesAndNewlines)
}

func save(sha: String) throws {
  @Dependency(\.fileSystem) var fileSystem
  try fileSystem.createDirectory(at: pfwDirectoryURL, withIntermediateDirectories: true)
  try fileSystem.write(
    Data(sha.trimmingCharacters(in: .whitespacesAndNewlines).utf8),
    to: shaURL
  )
}
