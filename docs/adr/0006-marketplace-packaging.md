# Marketplace packaging: a single-plugin marketplace at the repo root

The repository root carries `.claude-plugin/marketplace.json` listing one plugin, `learn-anything`, with `source: "./learn-anything"`, so the plugin installs with `/plugin install learn-anything --marketplace Meldron09/Understand-Anything` and the plugin directory stays self-contained (`${CLAUDE_PLUGIN_ROOT}` is the copied plugin folder; nothing in it reads from outside). The version lives only in `learn-anything/.claude-plugin/plugin.json`; the marketplace entry carries none, so the two cannot drift. Both manifests are validated in CI with `claude plugin validate --strict` (plugin folder and repo root), beside `scripts/lint-skills` and the deterministic test suites.

`claude plugin validate --strict learn-anything` passes with one non-blocking directory warning kept open: no listing icon (the validator asks for a 512 to 2048 px square PNG, used as the listing icon when the plugin is first submitted to a directory; v1 does not submit).

Rejected: a separate marketplace repository (a second repository to keep in step with the plugin, for no gain here).

Still to recheck once, after the first real marketplace install: `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PLUGIN_DATA}` substitution reaching a subagent was verified only under `--plugin-dir` (ticket 33).
