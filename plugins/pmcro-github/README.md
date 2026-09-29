# pmcro-github

Skills for running the PMCR-O loop on GitHub: `github-templates` applies the seed issue form, PR template, CODEOWNERS and workflows (replay trails in CI, plugin layout check, seed issue to queue PR). Applying is a dry run by default, and no workflow merges or pushes to a protected branch.

The `github-steward` file under `agents/` is a GitHub Copilot custom-agent definition. Codex
plugin installs expose this plugin's skills, but do not install that `.agent.md` file as a native
Codex agent.
