// Pmcro.AppHost: orchestrates the company runtime (Aspire 13.5.4, from the aspire-apphost template).
var builder = DistributedApplication.CreateBuilder(args);

// The local model runs in the host's own Ollama (eng/STACK.md pins 0.34.4), not a second copy in a container.
// Default: ConnectionStrings:chat in appsettings.json. Override with user secrets or environment variables.
var chat = builder.AddConnectionString("chat");

// The runtime reads company.json from the repo root: two levels up from this project.
var repoRoot = Path.GetFullPath(Path.Combine(builder.AppHostDirectory, "..", ".."));

builder.AddProject<Projects.Pmcro_Runtime>("runtime")
    .WithReference(chat)
    .WithEnvironment("Pmcro__RepoRoot", repoRoot)
    .WithHttpHealthCheck("/health");

builder.Build().Run();
