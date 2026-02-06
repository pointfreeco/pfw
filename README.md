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

## Installation Options

By default, `pfw` creates symbolic links from your AI tool's skills directory to a central location (`~/.pfw/skills/`). This allows skills to be updated in one place and immediately available to all tools.

### When to use `--copy`

If skills aren't being detected by your AI tool after installation, the tool may not support symbolic links. In this case, use the `--copy` flag to create full copies instead:

```sh
$ pfw install --tool <tool> --copy
```

> **Note:** When using `--copy`, skills are duplicated for each tool (using more disk space), and you'll need to re-run `pfw install --copy` after each update to get the latest skill versions.

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
