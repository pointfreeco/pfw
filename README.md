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

## Upgrade

To upgrade to the latest version of the CLI:

1. **Check your current version**

    ```sh
    $ pfw --version
    ```

2. **Upgrade the CLI**

    ```sh
    $ brew upgrade pfw
    ```

3. **Verify the new version**

    ```sh
    $ pfw --version
    ```

4. **Re-install the skills**

    After upgrading, re-install the skills to ensure you have the latest versions:

    ```sh
    $ pfw install --tool codex
    ```

## Supported AI Tools

| Tool | Install Path |
|------|--------------|
| Agents (generic) | `~/.agents/skills` |
| [Amp](https://ampcode.com/manual#agent-skills) | `~/.agents/skills` |
| [Antigravity](https://antigravity.google/docs/skills) | `~/.gemini/antigravity/global_skills` |
| [Claude](https://code.claude.com/docs/en/skills) | `~/.claude/skills` |
| [Codex](https://developers.openai.com/codex/skills/) | `~/.codex/skills` |
| [Copilot](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills) | `~/.copilot/skills` |
| [Cursor](https://cursor.com/docs/context/skills) | `~/.cursor/skills` |
| [Droid](https://docs.factory.ai/cli/configuration/skills) | `~/.factory/skills` |
| [Gemini](https://geminicli.com/docs/cli/skills/) | `~/.gemini/skills` |
| [Kimi](https://moonshotai.github.io/kimi-cli/en/customization/skills) | `~/.kimi/skills` |
| [Kiro](https://kiro.dev/docs/cli/custom-agents/configuration-reference/#skill-resources) | `~/.kiro/skills` |
| [OpenCode](https://opencode.ai/docs/skills/) | `~/.config/opencode/skills` |
