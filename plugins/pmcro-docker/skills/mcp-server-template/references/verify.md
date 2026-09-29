# Verify the template (runtime trail, needs a running Docker engine)

Every command goes through /docker-trail so it is logged.

1. /docker-baseline exits 0 (engine reachable).
2. Expand: scripts/new-mcp-server.ps1 -Name <name> -Out <relative dir> -DotnetVersion <x.y> -McpSdkVersion <v> -HostingVersion <v>.
3. docker build -t <name> <relative dir>  must exit 0.
4. Start with docker run -i --rm <name> and let an MCP client send initialize then tools/list; the Echo tool must be listed.
5. Must-fail: rename the [McpServerTool] Echo method attribute out, rebuild, and the tools/list check must go red.

The versions are tokens on purpose. Look up the current .NET image tag on mcr.microsoft.com and the current ModelContextProtocol and Microsoft.Extensions.Hosting package versions on nuget.org before expanding; none of them is verified in the authoring trail.
