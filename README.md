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

| Tool | Install Path | Documentation |
|------|--------------|---------------|
| Codex | `~/.codex/skills` | [OpenAI Codex Skills](https://developers.openai.com/codex/skills/) |
| Claude | `~/.claude/skills` | [Claude Code Skills](https://code.claude.com/docs/en/skills) |
| Cursor | `~/.cursor/skills` | [Cursor Skills](https://cursor.com/docs/context/skills) |
| Copilot | `~/.copilot/skills` | [GitHub Copilot Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) |
| Kiro | `~/.kiro/skills` | [Kiro Skills](https://kiro.dev/docs/cli/custom-agents/configuration-reference/#skill-resources) |
| Gemini | `~/.gemini/skills` | [Gemini CLI Skills](https://geminicli.com/docs/cli/skills/) |
| Antigravity | `~/.gemini/antigravity/global_skills` | [Antigravity Skills](https://antigravity.google/docs/skills) |
| OpenCode | `~/.config/opencode/skills` | [OpenCode Skills](https://opencode.ai/docs/skills/) |
| Kimi | `~/.kimi/skills` | [Kimi CLI Skills](https://moonshotai.github.io/kimi-cli/en/customization/skills) |
| Droid | `~/.factory/skills` | [Factory Droid Skills](https://docs.factory.ai/cli/configuration/skills) |
