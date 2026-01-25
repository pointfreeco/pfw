import Testing
import Foundation
@testable import pfw

@Suite("Install Path Validation Tests")
struct InstallPathValidationTests {

  @Test("Valid skills paths are accepted")
  func validSkillsPath() {
    #expect(Install.validateInstallPath("/Users/test/.claude/skills"))
    #expect(Install.validateInstallPath("/project/.codex/skills/my-skills"))
    #expect(Install.validateInstallPath("/home/user/.pfw/skills"))
    #expect(Install.validateInstallPath("/Users/test/.cursor/skills"))
  }

  @Test("Flexible directory naming is supported")
  func flexibleDirectoryNaming() {
    // Support different directory naming conventions
    #expect(Install.validateInstallPath("/Users/test/.github/skills"))
    #expect(Install.validateInstallPath("/project/.config/skills"))
    #expect(Install.validateInstallPath("/home/user/my-project/skills"))
  }

  @Test("Invalid paths are rejected")
  func invalidPathsRejected() {
    // Paths without /skills
    #expect(!Install.validateInstallPath("/tmp"))
    #expect(!Install.validateInstallPath("/Users/test/Downloads"))
    #expect(!Install.validateInstallPath("/project"))
    #expect(!Install.validateInstallPath("/home/user/.claude"))
  }

  @Test("Paths containing skills keyword are accepted")
  func pathsContainingSkillsAccepted() {
    // Any path with /skills is valid
    #expect(Install.validateInstallPath("/Users/test/.claude/skills"))
    #expect(Install.validateInstallPath("/Users/test/.codex/skills"))
    #expect(Install.validateInstallPath("/home/user/skills"))
    #expect(Install.validateInstallPath("/Users/test/.pfw/skills"))
  }
}

@Suite("Current Directory Detection Tests")
struct CurrentDirectoryDetectionTests {

  @Test("Dot is recognized as current directory")
  func dotIsCurrentDirectory() {
    #expect(Install.isCurrentDirectoryPath("."))
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
    var install = Install()
    install.local = false
    let currentDir = "/Users/test/.claude/skills"
    let url = install.resolveInstallURL(path: ".", currentDirectory: currentDir)
    #expect(url.path == currentDir)
  }

  @Test("Resolves to custom path when provided")
  func resolvesToCustomPath() {
    var install = Install()
    install.local = false
    let customPath = "/project/.claude/skills"
    let url = install.resolveInstallURL(path: customPath)
    #expect(url.path == customPath)
  }

  @Test("Resolves to global path when path is nil and not local")
  func resolvesToGlobalPath() {
    var install = Install()
    install.local = false
    let url = install.resolveInstallURL(path: nil)
    #expect(url.path.contains(".pfw/skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Resolves to local path when path is nil and local flag set")
  func resolvesToLocalPath() {
    var install = Install()
    install.local = true
    let url = install.resolveInstallURL(path: nil)
    #expect(url.path.hasSuffix(".pfw/skills"))
  }
}

@Suite("Tool Symlink Paths Tests")
struct ToolSymlinkPathsTests {

  @Test("Cursor global symlink path")
  func cursorGlobalPath() {
    let url = Install.Tool.cursor.symlinkPath(workspace: false)
    #expect(url.path.contains(".cursor/skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Cursor workspace symlink path")
  func cursorWorkspacePath() {
    let url = Install.Tool.cursor.symlinkPath(workspace: true)
    #expect(url.path.hasSuffix(".cursor/skills"))
  }

  @Test("Claude global symlink path")
  func claudeGlobalPath() {
    let url = Install.Tool.claude.symlinkPath(workspace: false)
    #expect(url.path.contains(".claude/skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Claude workspace symlink path")
  func claudeWorkspacePath() {
    let url = Install.Tool.claude.symlinkPath(workspace: true)
    #expect(url.path.hasSuffix(".claude/skills"))
  }

  @Test("Anti-Gravity global symlink path")
  func antigravityGlobalPath() {
    let url = Install.Tool.antigravity.symlinkPath(workspace: false)
    #expect(url.path.contains(".gemini/antigravity/global_skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Anti-Gravity workspace symlink path")
  func antigravityWorkspacePath() {
    let url = Install.Tool.antigravity.symlinkPath(workspace: true)
    #expect(url.path.hasSuffix(".agent/skills"))
  }

  @Test("Codex global symlink path")
  func codexGlobalPath() {
    let url = Install.Tool.codex.symlinkPath(workspace: false)
    #expect(url.path.contains(".codex/skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Copilot global symlink path")
  func copilotGlobalPath() {
    let url = Install.Tool.copilot.symlinkPath(workspace: false)
    #expect(url.path.contains(".copilot/skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Copilot workspace symlink path")
  func copilotWorkspacePath() {
    let url = Install.Tool.copilot.symlinkPath(workspace: true)
    #expect(url.path.hasSuffix(".github/skills"))
  }

  @Test("Kiro global symlink path")
  func kiroGlobalPath() {
    let url = Install.Tool.kiro.symlinkPath(workspace: false)
    #expect(url.path.contains(".kiro/skills"))
    #expect(url.path.hasPrefix("/"))
  }

  @Test("Gemini global symlink path")
  func geminiGlobalPath() {
    let url = Install.Tool.gemini.symlinkPath(workspace: false)
    #expect(url.path.contains(".gemini/skills"))
    #expect(url.path.hasPrefix("/"))
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

  @Test("Skills keyword validation is case sensitive")
  func skillsKeywordCaseSensitive() {
    // Lowercase /skills should match
    #expect(Install.validateInstallPath("/Users/test/.claude/skills"))
    // Capitalized /Skills or /SKILLS should not match (path is case-sensitive)
    #expect(!Install.validateInstallPath("/Users/test/.claude/Skills"))
    #expect(!Install.validateInstallPath("/Users/test/.claude/SKILLS"))
  }

  @Test("Path with multiple dots")
  func pathWithMultipleDots() {
    #expect(Install.validateInstallPath("/Users/test.user/.claude/skills"))
    #expect(Install.validateInstallPath("/Users/test/.config/.claude/skills"))
  }

  @Test("Path with trailing slashes")
  func pathWithTrailingSlashes() {
    #expect(Install.validateInstallPath("/Users/test/.claude/skills/"))
    #expect(Install.validateInstallPath("/Users/test/.claude/skills//"))
  }
}
