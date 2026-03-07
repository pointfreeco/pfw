@testable import pfw

struct TestEnvironment: Environment {
  var values: [String: String]

  init(_ values: [String: String] = [:]) {
    self.values = values
  }

  subscript(key: String) -> String? {
    values[key]
  }
}
