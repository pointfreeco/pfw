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

3. **Install Point-Free Way skills**

    The CLI uses a centralized approach with symlinks. You control both where skills are stored and where symlinks are created.

    **Two independent choices:**

    1. **Storage location** (where actual skill files live):
       - Global: `~/.pfw/skills/` (default - works across all projects)
       - Local: `.pfw/skills/` (with `--local` - project-specific, can be committed to git)

    2. **Symlink location** (where AI tools look for skills):
       - Global: `~/.cursor/skills/`, `~/.claude/skills/`, etc. (default)
       - Workspace: `.cursor/skills/`, `.claude/skills/`, etc. (with `--workspace`)

    **Common workflows:**

    ```sh
    # Global skills, global symlinks (recommended for personal skills)
    $ pfw install

    # Global skills, workspace symlinks (access global skills per-project)
    $ pfw install --workspace

    # Local skills, workspace symlinks (team-shared project skills)
    # Note: --local automatically enables --workspace
    $ pfw install --local

    # Install for specific tools only
    $ pfw install --tools cursor claude --local

    # Install for all supported tools
    $ pfw install --all --local
    ```

    > **Note:** `--local` automatically enables `--workspace` because local skills from different projects would conflict if symlinked to the same global location.

    **Supported AI tools:**

    | Tool | Global (user-level) | Workspace (project-level) |
    |------|---------------------|---------------------------|
    | Codex | `~/.codex/skills` | `.codex/skills` |
    | Claude | `~/.claude/skills` | `.claude/skills` |
    | Cursor | `~/.cursor/skills` | `.cursor/skills` |
    | Kiro | `~/.kiro/skills` | `.kiro/skills` |
    | Gemini | `~/.gemini/skills` | `.gemini/skills` |
    | Anti-Gravity | `~/.gemini/antigravity/global_skills` | `.agent/skills` |

    All symlinks point to either `~/.pfw/skills/` (global) or `.pfw/skills/` (local).
