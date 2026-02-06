# The Point-Free Way CLI

A CLI tool for downloading and managing [Point-Free Way](https://www.pointfree.co/the-way) skills.

## Quick start

1. **Install the CLI**

    Using [Homebrew](https://brew.sh):

    ```sh
    $ brew install pointfreeco/tap/pfw
    ```

2. **Log into your Point-Free account**

    ```sh
    $ pfw login
    ```

3. **Fetch the latest Point-Free Way skills**

    ```sh
    $ pfw install --tool codex
    ```

## Supported AI Tools

| `pfw install --tool` | Install Path |
|------|--------------|
| `agents` (generic) | `~/.agents/skills` |
| [`amp`](https://ampcode.com/manual#agent-skills) | `~/.agents/skills` |
| [`antigravity`](https://antigravity.google/docs/skills) | `~/.gemini/antigravity/skills` |
| [`claude`](https://code.claude.com/docs/en/skills) | `~/.claude/skills` |
| [`codex`](https://developers.openai.com/codex/skills/) | `~/.codex/skills` |
| [`copilot`](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) | `~/.copilot/skills` |
| [`cursor`](https://cursor.com/docs/context/skills) | `~/.cursor/skills` |
| [`droid`](https://docs.factory.ai/cli/configuration/skills) | `~/.factory/skills` |
| [`gemini`](https://geminicli.com/docs/cli/skills/) | `~/.gemini/skills` |
| [`kimi`](https://moonshotai.github.io/kimi-cli/en/customization/skills) | `~/.kimi/skills` |
| [`kiro`](https://kiro.dev/docs/cli/custom-agents/configuration-reference/#skill-resources) | `~/.kiro/skills` |
| [`opencode`](https://opencode.ai/docs/skills/) | `~/.config/opencode/skills` |
| [`xcode:claude`](https://developer.apple.com/documentation/Xcode/setting-up-coding-intelligence#Customize-the-Codex-and-Claude-Agent-environments) | `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/skills` |
| [`xcode:codex`](https://developer.apple.com/documentation/Xcode/setting-up-coding-intelligence#Customize-the-Codex-and-Claude-Agent-environments) | `~/Library/Developer/Xcode/CodingAssistant/codex/skills` |
