# pmcro-authoring

Skills for authoring agent skills: `create-skill` scaffolds a skill from templates, validates it, and keeps it as a proposal until Shawn or a Chief approves or rejects it. Template engines are not rebuilt here: templating of .NET projects reuses the dotnet/skills plugin `dotnet-template-engine`.

The `skill-author` file under `agents/` is a GitHub Copilot custom-agent definition. Codex
plugin installs expose this plugin's skills, but do not install that `.agent.md` file as a native
Codex agent.
