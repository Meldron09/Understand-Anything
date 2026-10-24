# Research: Claude Code plugin and skill constraints

Ticket: Meldron09/Understand-Anything#14 (map #1). Fetched 2026-10-24 from primary sources only. Where the docs are silent the entry says **unknown**. Nothing was installed or executed.

Source keys (all fetched 2026-10-24):

- [SKILLS] https://code.claude.com/docs/en/skills
- [SUBAGENTS] https://code.claude.com/docs/en/sub-agents
- [MANIFEST] https://code.claude.com/docs/en/plugins-reference (plugin.json reference; also served as /plugins/manifest-reference)
- [COMPONENTS] https://code.claude.com/docs/en/plugins/components
- [DEPS] https://code.claude.com/docs/en/plugins/dependencies
- [MKT-REF] https://code.claude.com/docs/en/plugins/marketplace-reference
- [MKT-HOST] https://code.claude.com/docs/en/plugins/host-marketplace
- [LOADING] https://code.claude.com/docs/en/plugins/loading
- [BP] https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- [OVERVIEW] https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview
- [SPEC] https://agentskills.io/specification (open Agent Skills standard that the Anthropic docs defer to)

## A. Plugin manifest and layout

**A1. The manifest is optional; only `name` is required if present.** Path `.claude-plugin/plugin.json`. Everything else (skills/, agents/, hooks/, ...) lives at the plugin root, never inside `.claude-plugin/`. [MANIFEST "Manifest file"]

**A2. Standard layout.** `skills/<name>/SKILL.md`, `agents/*.md`, `hooks/hooks.json`, `.mcp.json`, `bin/`, `settings.json`, `commands/` (legacy; prefer skills). A `scripts/` folder is a convention only. [MANIFEST "Standard layout"; COMPONENTS "Hooks"]

**A3. `name` rules.** Kebab-case, no spaces, `@`, `:`, or path separators. `claude plugin validate` errors on names starting `claude-`, `anthropic-`, `anthropics-`, `cc-plugin-` or equal to `claude`/`anthropic`; warns if `claude`/`anthropic` appears as a whole word. `learn-anything` is clean. Every component is namespaced under the plugin name. [MANIFEST "name"]

**A4. Useful optional fields:** `displayName`, `version`, `description`, `author{name,email,url}`, `homepage`, `repository`, `license` (SPDX), `keywords`, `defaultEnabled`, `dependencies`, `userConfig`, `settings`, `skills`, `agents`, `hooks`, `mcpServers`. Unknown top-level keys are stripped (warning in validate); unknown keys inside `userConfig`/`channels`/`lspServers`/`monitors` entries are hard errors. [MANIFEST "Fields", "Unrecognized fields"]

**A5. Path rules.** Every manifest component path starts with `./`, resolves inside the plugin root, and must exist; `..` fails. `skills` ADDS to the default `skills/` scan; `commands`, `agents`, `outputStyles` REPLACE their default dirs; `hooks`/`mcpServers` merge. `agents` entries must be `.md` files (directories not accepted). [MANIFEST "Path rules"]

**A6. Files outside the plugin directory are not available at runtime.** Marketplace plugins are copied to `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`; a script reading `../shared` finds nothing. Symlinks resolving elsewhere in the same marketplace are dereferenced at copy; symlinks leaving the marketplace are skipped. [LOADING "In-place and copied plugins"; MKT-HOST "Share files within a marketplace with symlinks"]

**A7. State must not live in the plugin dir.** `${CLAUDE_PLUGIN_ROOT}` changes on every version; use `${CLAUDE_PLUGIN_DATA}` (`~/.claude/plugins/data/<id>/`, survives updates) for caches. Both are substituted inline in skill/agent Markdown bodies but are NOT in the environment of Bash commands Claude runs. `${CLAUDE_SKILL_DIR}` also works in skills. [MANIFEST "Environment variables"; SKILLS "String substitutions"]

**A8. `CLAUDE.md` at the plugin root is not loaded** (validate warns). Instructions must go in a skill. [COMPONENTS "Skills"]

**A9. `bin/` is on the Bash tool's PATH while the plugin is enabled**, but claude.ai and Cowork refuse to install a plugin with a top-level `bin/`. Use `scripts/` + `${CLAUDE_PLUGIN_ROOT}` for portability. [COMPONENTS "Executables"; MKT-HOST "Distribute through organization settings"]

**A10. Marketplace requirements.** `.claude-plugin/marketplace.json` needs `name`, `owner{name}`, `plugins[]` (each `name` + `source`). Relative-path sources must start `./`, no `..`, and fail if the marketplace is added as a bare URL. Reserved marketplace names include `claude-*`/`anthropic-*` variants. [MKT-REF "Marketplace file", "Top-level fields", "Relative path plugin source"]

**A11. Versioning.** `version` in plugin.json wins over the marketplace entry; setting it pins users until it changes; omitting it tracks commit SHA. Do not set it in both places. `claude plugin validate [--strict]` is the authoritative check; `claude plugin tag --push` creates `<plugin>--v<version>` tags. [LOADING "How Claude Code computes the version"; MKT-HOST "Release a new version"; DEPS "Create a release tag"]

**A12. Other surfaces load fewer components.** Skills-only plugins are the most portable; claude.ai/Cowork have a component support table (not fetched; see https://claude.com/docs/plugins/platform-support). Local stdio MCP servers do not run on claude.ai. [COMPONENTS "Reach users on claude.ai and Cowork"]

## B. Skill frontmatter and invocation control

**B1. Claude Code accepts all-optional frontmatter** (only `description` recommended; unrecognized keys ignored). Fields: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, plus spec fields `license`, `compatibility`, `metadata` (accepted, not acted on). [SKILLS "Frontmatter reference"]

**B2. Portability trap.** Outside Claude Code (claude.ai uploads, Skills API) only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools` are allowed and other keys are a hard error. Using `context: fork`, `model`, etc. ties the skill to Claude Code. [SKILLS "Frontmatter reference"]

**B3. Name.** Spec: 1-64 chars, lowercase letters/digits/hyphens, no leading/trailing/double hyphen, must match directory name. Anthropic docs add: no XML tags, no reserved words `anthropic`, `claude`. Plugin skill command is `/<plugin>:<skill>`; a frontmatter `name` replaces only the last segment. [SPEC "name field"; BP "Skill structure"; SKILLS "Plugin namespacing"]

**B4. Who can invoke (this matters for mode skills).**

| Frontmatter | User | Claude | Description in context |
|---|---|---|---|
| default | yes | yes | always |
| `disable-model-invocation: true` | yes | not on its own | no |
| `user-invocable: false` | no | yes | always |

`disable-model-invocation: true` also blocks preloading into subagents. [SKILLS "Control who invokes a skill"; SUBAGENTS "Preloading skills"]

**B5. `allowed-tools` is pre-approval, not a restriction.** It lets Claude use listed tools without prompting for the turn that invokes the skill; the grant clears on the next user message. `disallowed-tools` removes tools from Claude's pool while the skill is active. [SKILLS "Frontmatter reference"]

**B6. `model` and `effort` apply to the current turn only** and are not persisted. [SKILLS "Frontmatter reference"]

**B7. `` !`cmd` `` dynamic injection aborts the whole skill invocation on a non-zero exit** (except exit 1 from search/compare commands); commands are permission-checked. Append `|| true` for optional probes. [SKILLS "Dynamic context injection"]

**B8. Frontmatter YAML errors silently drop metadata:** `/skill` still works but Claude cannot match the description. `claude plugin validate` finds them. [SKILLS "Skill not triggering"]

## C. Description triggering and length

**C1. Descriptions are the only trigger signal.** Level 1 metadata (name + description) is always in context; ~100 tokens per skill. The body loads only on invocation. [OVERVIEW "Level 1"; BP "Writing effective descriptions"]

**C2. Length limits conflict; use the stricter.** Spec/API: description 1-1,024 chars. Claude Code: `description` + `when_to_use` combined are truncated at 1,536 chars in the listing (configurable via `skillListingMaxDescChars`). Put the key use case first. [SPEC; SKILLS "Frontmatter reference"; SKILLS "Skill descriptions are cut short"]

**C3. The whole listing has a budget.** 1% of the model's context window by default; when it overflows, descriptions are dropped starting from least-used skills (names are always kept). Raise with `skillListingBudgetFraction` or `SLASH_COMMAND_TOOL_CHAR_BUDGET`; per-skill `"name-only"` via `skillOverrides`. Many mode skills each carrying a long description crowd the budget. [SKILLS "Skill descriptions are cut short"]

**C4. Authoring rules.** Third person ("Processes...", not "I can..."); say what AND when; include natural trigger keywords; avoid vague text ("Helps with documents"). [BP "Writing effective descriptions"]

**C5. Precision tools.** `paths` globs restrict automatic activation (relative to cwd); `disable-model-invocation` removes the description from context entirely; `claude plugin eval` with a `tool_used: Skill` grader measures trigger rate. [SKILLS "Frontmatter reference", "Skill not triggering"]

**C6. Skills are re-listed live.** Edits to skills under watched dirs apply within the session; plugin changes to `agents/`, `hooks/`, `.mcp.json` need `/reload-plugins`. [SKILLS "Live change detection"]

## D. Supporting files and progressive disclosure

**D1. Three levels:** metadata always; SKILL.md body on trigger (spec recommends < 5,000 tokens); bundled files only when read; scripts run via bash and only their output enters context. [OVERVIEW "How Skills work"; SPEC "Progressive disclosure"]

**D2. Keep `SKILL.md` under 500 lines** and move detail to sibling files, referenced from SKILL.md with a line saying what each holds and when to read it. [SKILLS "Add supporting files"; BP "Progressive disclosure patterns"; SPEC]

**D3. References must be one level deep from SKILL.md.** Nested chains (SKILL -> a.md -> b.md) risk partial reads (`head -100`). Reference files over 100 lines need a table of contents at the top. [BP "Avoid deeply nested references", "Structure longer reference files"]

**D4. Domain-organized references are the documented pattern for "load only the chosen branch".** `SKILL.md` as router + `reference/<domain>.md`. Spec convention dirs: `scripts/`, `references/`, `assets/`. Use forward slashes; descriptive file names. [BP "Pattern 2"; SPEC "Optional directories"]

**D5. Invoked skill content is a single message that stays in context** and is not re-read. After compaction only the first 5,000 tokens of each invoked skill are re-attached, within a 25,000-token combined budget (most recent first). Put the critical instructions at the top. [SKILLS "Skill content lifecycle", "Claude stops following a skill"]

**D6. Reference files are read by the model with Read/bash, not injected.** Making the model read the right per-mode file is a prompt-level instruction, not a platform guarantee. [BP "Runtime environment"] (Whether the model reliably skips unchosen files is untested here.)

## E. Subagents: spawning, nesting, definition

**E1. A skill cannot itself spawn anything.** Skills are instructions. A skill body can tell Claude to use the Agent tool; or `context: fork` runs the whole skill as a subagent. Docs do not explicitly say "a main-thread skill may instruct Claude to spawn subagents", but subagents spawned from the main conversation are the documented default behavior. [SKILLS "Run skills in a subagent"; SUBAGENTS "Run subagents in foreground or background"]

**E2. `context: fork`.** Starts a new subagent of type `agent` (default `general-purpose`; built-ins `Explore`, `Plan`; custom from `.claude/agents/`) with the skill body as its prompt. It does NOT see conversation history, so the skill must be self-contained. Runs in the background by default (`background: false` to wait; needs v2.1.218+). Skills with only guidelines and no task return nothing useful. [SKILLS "Run skills in a subagent"]
  - **Unknown:** whether `agent:` accepts plugin-scoped names such as `learn-anything:renderer`. The page lists only built-in and `.claude/agents/` examples.

**E3. Isolation and return value.** A subagent starts with a fresh context; it receives its system prompt, Claude's delegation message, CLAUDE.md (not for Explore/Plan, nor with `omitClaudeMd`), a git-status snapshot, and preloaded skills. Only its final summary returns to the parent. This matches the "minimal brief, short summary plus file path" requirement. [SUBAGENTS "Context isolation"]

**E4. Nesting.** Subagents can spawn subagents, up to three layers below the main conversation by default; at the limit the `Agent` tool is withheld. Tune with `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` (1 disables nesting). A fork cannot spawn forks. Omit `Agent` from a subagent's `tools` to stop it spawning. This is a user env var, not something a plugin sets. [SUBAGENTS "Spawning subagents and nesting", "How forks differ"]

**E5. Concurrency default is 20** (`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`). [SUBAGENTS "Spawning subagents and nesting"]

**E6. Background is the default for Claude-spawned subagents, with a reduced tool set:** Read, Grep, Glob, LSP, Bash, PowerShell, Edit, Write, NotebookEdit, WebFetch, WebSearch, TodoWrite, Skill, ToolSearch, worktree tools, Monitor, TaskStop, SendMessage, Artifact (+ all MCP tools). `AskUserQuestion` is always removed from every subagent, so a subagent cannot interview the learner. Interactive intake must run in the main thread. [SUBAGENTS "Available tools"]

**E7. Plugins define subagents as `agents/<name>.md`** (frontmatter + system-prompt body); namespaced `<plugin>:<name>`, subfolders add segments (`agents/review/x.md` -> `plugin:review:x`). Only `name` and `description` are required in the subagent format. [COMPONENTS "Agents"; SUBAGENTS "Subagent file format"]

**E8. Plugin agents ignore `permissionMode`, `hooks`, `mcpServers`, `initialPrompt`.** Supported: `name`, `description`, `model`, `effort`, `maxTurns`, `autoCompactWindow`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `omitClaudeMd`, `isolation` (`"worktree"` only), `color`. [COMPONENTS "Frontmatter fields in plugin agents"]

**E9. A subagent can preload skills via `skills:`** (full content injected at startup, first 32 names), but skills with `disable-model-invocation: true` cannot be preloaded. It can still call other skills via the Skill tool unless `Skill` is removed. [SUBAGENTS "Preloading skills"]

**E10. Model per subagent:** resolved as per-call parameter > frontmatter `model` > `CLAUDE_CODE_SUBAGENT_MODEL` > parent. Frontmatter accepts `sonnet`, `opus`, `haiku`, `inherit`, or a full ID. [SUBAGENTS "Model selection"]

**E11. Subagent descriptions have their own 15,000-token combined budget** (warning only; all still load). [SUBAGENTS "Understand automatic delegation"]

**E12. Subagent transcripts are written under `~/.claude/projects/.../subagents/` and cleaned up after 30 days by default.** Not a place for lesson artifacts. [SUBAGENTS "Resuming subagents"]

## F. Dependencies and checking for other skills or tools

**F1. The only declarative dependency mechanism is plugin-to-plugin.** `plugin.json` `dependencies`: `"name"`, `"name@marketplace"`, or `{name, marketplace, version}`. There is no manifest field for depending on a bare skill, a CLI binary, an MCP server, or a Python package. [MANIFEST "dependencies"; DEPS "Declare dependencies"]

**F2. Dependency behavior.** Dependencies are auto-installed on `claude plugin install`, `/reload-plugins`, auto-update. Version ranges are semver, resolved against git tags `<plugin>--v<ver>`. If a dependency is disabled, the dependent plugin is disabled with an error. [DEPS "Declare dependencies", "Test a plugin and its dependency locally"]

**F3. Cross-marketplace dependencies are blocked by default.** The root marketplace must list the target in `allowCrossMarketplaceDependenciesOn`, unless the user already has it installed at the same scope. A `command`-source dependency is never auto-installed. [DEPS "Depend on a plugin from another marketplace", "Constrain a dependency that has a non-git source"]

**F4. Implication for grilling/domain-modeling.** Those are user-level skills here, not plugins, so `dependencies` cannot reach them. They can be depended on only if someone packages them as a plugin in a marketplace. Alternatives: (a) copy the needed behavior into learn-anything, (b) symlink (only works within one marketplace, dereferenced at cache copy), (c) soft-reference by name and degrade. [MKT-HOST "Share files within a marketplace with symlinks"; DEPS]

**F5. Skill-calls-skill is not documented.** The Skill tool lets Claude invoke any model-invocable skill, governed by `Skill(name)` permission rules; plugin skills are addressed `plugin:skill` (example `anthropic-skills:pdf`). **Unknown:** what happens if a skill body tells Claude to invoke a skill that is not installed (assume it fails or is ignored; the docs do not specify). [SKILLS "Restrict Claude's skill access"]

**F6. Documented ways to declare or check external requirements (all soft):**
  - `compatibility` frontmatter (<= 500 chars, e.g. "Requires git, docker, jq") is informational; Claude Code does not act on it. [SPEC "compatibility field"; SKILLS "Frontmatter reference"]
  - Instruct the model in the body to check (`command -v x`) and fall back; BP says do not assume tools are installed and list packages explicitly. [BP "Avoid assuming tools are installed", "Package dependencies"]
  - A `SessionStart` hook in `hooks/hooks.json` can check/install into `${CLAUDE_PLUGIN_DATA}`. Plugin hooks fire for the whole session once the plugin loads. [COMPONENTS "Hooks", "Install dependencies into the data directory"]
  - Node deps auto-install only with a `package.json` plus lockfile, registry packages only, no scripts, 60 s timeout; Python deps are not auto-installed. [LOADING "Node.js package dependencies"]
  - `userConfig` prompts for values at enable time (not a tool check). [MANIFEST "User configuration"]

**F7. Runtime differences.** Claude Code skills have full network access; the API has none and no runtime package install; claude.ai varies. Claude Code discourages global package installs. Video renderers needing local binaries (ffmpeg, node, python) therefore work only in Claude Code. [OVERVIEW "Runtime environment constraints"]

## G. Size and token limits (summary)

| Item | Limit | Source |
|---|---|---|
| name | 64 chars | SPEC, BP |
| description (spec/API) | 1,024 chars | SPEC, BP |
| description + when_to_use (Claude Code listing) | 1,536 chars | SKILLS |
| compatibility | 500 chars | SPEC |
| SKILL.md body | < 500 lines; < 5,000 tokens recommended | BP, SPEC |
| Skill listing budget | 1% of context window (default) | SKILLS |
| Post-compaction re-attach | 5,000 tokens/skill, 25,000 total | SKILLS |
| Subagent descriptions | 15,000 tokens combined (warning) | SUBAGENTS |
| Preloaded skills per subagent | first 32 | SUBAGENTS |
| Subagent depth / concurrency | 3 / 20 (env-tunable) | SUBAGENTS |
| Reference file TOC | required over 100 lines | BP |
| Archive plugin download | 256 MiB zip, 1 GiB extracted | MKT-HOST |

## H. Implications for learn-anything

1. **Plugin shape:** `learn-anything/.claude-plugin/plugin.json` (name, version, description, author, license, keywords), `skills/` (one directory per skill), `agents/` for renderer/worker subagents, optional `hooks/hooks.json`. No `bin/`, no `CLAUDE.md`, no files outside the plugin dir.
2. **Lean SKILL.md + per-mode references is the documented pattern (D2-D4).** Router SKILL.md names each mode and links `references/<mode>.md` one level deep; ship a TOC in any reference > 100 lines; put critical rules in the first ~5,000 tokens (compaction).
3. **Mode skills: choose invocation flags deliberately (B4).** `disable-model-invocation: true` hides the skill from Claude entirely, so a router cannot hand off to it. If mode skills must be handoff targets, keep them model-invocable, or use `user-invocable: false`. Alternatively make modes reference files of one skill rather than separate skills (also avoids the listing budget in C3).
4. **Descriptions:** stay <= 1,024 chars (portable), third person, what + when, key trigger first. Each description should state inline vs spawns subagents (map requirement), which fits the same text.
5. **Intake must stay in the main thread (E6):** `AskUserQuestion` is stripped from every subagent, and background subagents default. Only render/ingest-style work should be forked.
6. **Subagent budget design:** depth 3 and 20 concurrent are defaults users may change; design for depth <= 2 (router -> renderer -> scene worker is already 2 below main), return only summary + path (E3), write artifacts to the learner's working directory, not `${CLAUDE_PLUGIN_ROOT}` (A7) nor subagent transcripts (E12).
7. **Do not rely on `context: fork` with a plugin-scoped `agent:` until verified** (E2 unknown); safer to have the skill instruct Claude to spawn the plugin agent by scoped name `learn-anything:<agent>` and test it.
8. **Plugin agents cannot carry hooks/mcpServers/permissionMode (E8):** put any hook in the plugin's `hooks/hooks.json`; do not depend on per-agent permission modes.
9. **Dependencies (F):** do not assume grilling/domain-modeling exist. Either vendor a minimal intake protocol into learn-anything, or document an optional dependency and degrade to a built-in question set when the skill is missing. Declare external binaries in `compatibility`, probe with a command at run time, and fall back to text (marketplace standard: documented dependencies, graceful degradation).
10. **Portability:** a skills-only core stays valid on claude.ai (frontmatter limited to the spec subset, B2); anything using `context: fork`, `model`, `allowed-tools` patterns, subagents or local renderers is Claude Code-only and should be declared as such.
11. **Free/local video renderers** depend on local binaries; plugins cannot declare or install them (F1, F6). A renderer skill must check availability first and fall back to a non-video mode.
12. **Validate in CI:** `claude plugin validate --strict` on the plugin and marketplace; `claude plugin tag` for releases; pin `version`.

## Unknowns to resolve before the spec locks

- Whether `context: fork` `agent:` accepts `plugin:name` (E2).
- Behavior when a skill references a missing skill (F5).
- Whether Claude reliably reads only the chosen per-mode reference file (D6); needs an eval (`claude plugin eval`) once a skeleton exists.
- Cowork/claude.ai component support table (A12); not fetched.
