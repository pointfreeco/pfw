import Dependencies
import Foundation

protocol Environment: Sendable {
  subscript(key: String) -> String? { get }
}

struct LiveEnvironment: Environment {
  subscript(key: String) -> String? {
    ProcessInfo.processInfo.environment[key]
  }
}

enum EnvironmentKey: DependencyKey {
  static var liveValue: any Environment { LiveEnvironment() }
}

extension DependencyValues {
  var environment: any Environment {
    get { self[EnvironmentKey.self] }
    set { self[EnvironmentKey.self] = newValue }
  }
}
