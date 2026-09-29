# pmcro-docs

Skills for the company docs product: `docfx` authors and builds documentation with DocFX, and `simulate` runs a plan as a dry run and records a simulated trail without writing product files.

The `docs-writer` file under `agents/` is a GitHub Copilot custom-agent definition. Codex
plugin installs expose this plugin's skills, but do not install that `.agent.md` file as a native
Codex agent.
