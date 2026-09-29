# pmcro-docker

Skills for Docker work inside trails: `docker-baseline` records versions and whether the engine is reachable, `docker-trail` logs every docker command into an open trail, `mcp-server-template` expands a .NET MCP server with a Dockerfile, and `notebook-test` validates a test notebook without running it. Hardware gate: learn/STATE.md records crashes during Docker builds on the company PC, so builds and runs wait for Shawn.

The `docker-operator` file under `agents/` is a GitHub Copilot custom-agent definition. Codex
plugin installs expose this plugin's skills, but do not install that `.agent.md` file as a native
Codex agent.
