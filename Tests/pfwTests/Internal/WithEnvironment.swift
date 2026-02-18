import Foundation

func withEnvironment(
  _ key: String,
  _ value: String?,
  _ operation: () throws -> Void
) rethrows {
  let previous = getenv(key).map { String(cString: $0) }
  if let value {
    setenv(key, value, 1)
  } else {
    unsetenv(key)
  }
  defer {
    if let previous {
      setenv(key, previous, 1)
    } else {
      unsetenv(key)
    }
  }
  try operation()
}
