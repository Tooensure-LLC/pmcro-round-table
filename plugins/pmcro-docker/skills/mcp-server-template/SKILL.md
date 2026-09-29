---
name: mcp-server-template
description: Expand a .NET MCP server template with a Dockerfile into a new folder so anyone can build and run the same server anywhere. USE FOR the first Docker skills product, an MCP server that lists a tool over stdio. DO NOT USE to build or run the image (use docker-trail) or to pick package versions from memory.
---

# /mcp-server-template

Role: maker.

## Steps

1. Run `/docker-baseline`. If it exits 2, stop and ask Shawn.
2. Look up the current .NET image tag, the `ModelContextProtocol` package version and the `Microsoft.Extensions.Hosting` version from the official sources. Do not guess them.
3. Expand: `scripts/new-mcp-server.ps1 -Name <Name> -Out <relative folder> -DotnetVersion <x.y> -McpSdkVersion <v> -HostingVersion <v>`.
4. Verify through `/docker-trail` as written in `references/verify.md`: build, start, an MCP client lists the Echo tool, and a broken tool turns the check red.

## Rules

- Files come from `assets/template/`; tokens are `{{ProjectName}}`, `{{DotnetVersion}}`, `{{McpSdkVersion}}`, `{{HostingVersion}}`.
- The container runs as the non-root `app` user. No `--privileged`, no docker.sock mount.
- Listed in the marketplace only after a Checker PASS and an Auditor AUDIT-PASS.
