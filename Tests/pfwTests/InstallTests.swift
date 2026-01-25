import Testing
import Foundation
@testable import pfw

@Suite("Install Path Validation Tests")
struct InstallPathValidationTests {

  @Test("Valid Claude skills path is accepted")
  func validClaudeSkillsPath() {
    #expect(Install.validateInstallPath("/Users/test/.claude/skills", tool: .claude))
    #expect(Install.validateInstallPath("/project/.claude/skills/my-skills", tool: .claude))
    #expect(Install.validateInstallPath("/home/user/.claude/skills", tool: .claude))
  }

  @Test("Valid Codex skills path is accepted")
  func validCodexSkillsPath() {
    #expect(Install.validateInstallPath("/Users/test/.codex/skills", tool: .codex))
    #expect(Install.validateInstallPath("/project/.codex/skills/custom", tool: .codex))
    #expect(Install.validateInstallPath("/home/user/.codex/skills", tool: .codex))
  }

  @Test("Invalid paths are rejected")
  func invalidPathsRejected() {
    // Paths without .claude/skills or .codex/skills
    #expect(!Install.validateInstallPath("/tmp", tool: .claude))
    #expect(!Install.validateInstallPath("/Users/test/Downloads", tool: .claude))
    #expect(!Install.validateInstallPath("/project", tool: .codex))
    #expect(!Install.validateInstallPath("/home/user/.claude", tool: .claude))
    #expect(!Install.validateInstallPath("/home/user/skills", tool: .claude))
  }

  @Test("Wrong tool paths are rejected")
  func wrongToolPathsRejected() {
    // Claude path with Codex tool
    #expect(!Install.validateInstallPath("/Users/test/.claude/skills", tool: .codex))
    // Codex path with Claude tool
    #expect(!Install.validateInstallPath("/Users/test/.codex/skills", tool: .claude))
  }
}

@Suite("Current Directory Detection Tests")
struct CurrentDirectoryDetectionTests {

  @Test("Dot is recognized as current directory")
  func dotIsCurrentDirectory() {
    #expect(Install.isCurrentDirectoryPath("."))
  }

  @Test("'current' keyword is recognized as current directory")
  func currentKeywordIsCurrentDirectory() {
    #expect(Install.isCurrentDirectoryPath("current"))
  }

  @Test("nil is not current directory")
  func nilIsNotCurrentDirectory() {
    #expect(!Install.isCurrentDirectoryPath(nil))
  }

  @Test("Absolute paths are not current directory")
  func absolutePathsNotCurrentDirectory() {
    #expect(!Install.isCurrentDirectoryPath("/tmp"))
    #expect(!Install.isCurrentDirectoryPath("/Users/test/.claude/skills"))
    #expect(!Install.isCurrentDirectoryPath("~/project"))
  }

  @Test("Relative paths are not current directory")
  func relativePathsNotCurrentDirectory() {
    #expect(!Install.isCurrentDirectoryPath("./subdir"))
    #expect(!Install.isCurrentDirectoryPath("../parent"))
  }
}

@Suite("Install URL Resolution Tests")
struct InstallURLResolutionTests {

  @Test("Resolves to current directory when path is dot")
  func resolvesToCurrentDirectoryForDot() {
    let currentDir = "/Users/test/.claude/skills"
    let url = Install.resolveInstallURL(path: ".", tool: .claude, currentDirectory: currentDir)
    #expect(url.path == currentDir)
  }

  @Test("Resolves to current directory when path is 'current'")
  func resolvesToCurrentDirectoryForCurrentKeyword() {
    let currentDir = "/Users/test/.codex/skills"
    let url = Install.resolveInstallURL(path: "current", tool: .codex, currentDirectory: currentDir)
    #expect(url.path == currentDir)
  }

  @Test("Resolves to custom path when provided")
  func resolvesToCustomPath() {
    let customPath = "/project/.claude/skills"
    let url = Install.resolveInstallURL(path: customPath, tool: .claude)
    #expect(url.path == customPath)
  }

  @Test("Resolves to default path when path is nil for Claude")
  func resolvesToDefaultPathForClaude() {
    let url = Install.resolveInstallURL(path: nil, tool: .claude)
    #expect(url.path.contains(".claude/skills/the-point-free-way"))
  }

  @Test("Resolves to default path when path is nil for Codex")
  func resolvesToDefaultPathForCodex() {
    let url = Install.resolveInstallURL(path: nil, tool: .codex)
    #expect(url.path.contains(".codex/skills/the-point-free-way"))
  }
}

@Suite("Tool Default Paths Tests")
struct ToolDefaultPathsTests {

  @Test("Claude default path contains correct pattern")
  func claudeDefaultPath() {
    let path = Install.Tool.claude.defaultInstallPath
    #expect(path.path.contains(".claude/skills/the-point-free-way"))
  }

  @Test("Codex default path contains correct pattern")
  func codexDefaultPath() {
    let path = Install.Tool.codex.defaultInstallPath
    #expect(path.path.contains(".codex/skills/the-point-free-way"))
  }
}

@Suite("Edge Cases Tests")
struct EdgeCasesTests {

  @Test("Empty string path is not current directory")
  func emptyStringNotCurrentDirectory() {
    #expect(!Install.isCurrentDirectoryPath(""))
  }

  @Test("Whitespace path is not current directory")
  func whitespaceNotCurrentDirectory() {
    #expect(!Install.isCurrentDirectoryPath(" "))
    #expect(!Install.isCurrentDirectoryPath("  "))
  }

  @Test("Case sensitive tool validation")
  func caseSensitiveToolValidation() {
    // .claude (lowercase) should match
    #expect(Install.validateInstallPath("/Users/test/.claude/skills", tool: .claude))
    // .Claude (capitalized) should not match
    #expect(!Install.validateInstallPath("/Users/test/.Claude/skills", tool: .claude))
  }

  @Test("Path with multiple dots")
  func pathWithMultipleDots() {
    #expect(Install.validateInstallPath("/Users/test.user/.claude/skills", tool: .claude))
    #expect(Install.validateInstallPath("/Users/test/.config/.claude/skills", tool: .claude))
  }

  @Test("Path with trailing slashes")
  func pathWithTrailingSlashes() {
    #expect(Install.validateInstallPath("/Users/test/.claude/skills/", tool: .claude))
    #expect(Install.validateInstallPath("/Users/test/.claude/skills//", tool: .claude))
  }
}
