using System.Diagnostics;
using System.Text.Json;
using Microsoft.Agents.AI;
using Microsoft.Extensions.AI;
using Pmcro.Runtime.Company;

namespace Pmcro.Tests;

/// <summary>Proves the runtime reads the same company definition every other host reads.</summary>
public class CompanyTests
{
    private static readonly string Root = CompanyDefinition.FindRepoRoot(AppContext.BaseDirectory);

    [Fact]
    public void EverySeatInCompanyJsonBecomesAnAgentWithItsGeneratedPrompt()
    {
        var company = CompanyDefinition.Load(Root);
        using var doc = JsonDocument.Parse(File.ReadAllText(Path.Combine(Root, "company.json")));
        var ids = doc.RootElement.GetProperty("bots").EnumerateArray().Select(b => b.GetProperty("id").GetString()).ToList();

        Assert.Equal(ids, company.Seats.Select(s => s.Id));
        Assert.All(company.Seats, s => Assert.Contains(s.Title, s.Instructions));
    }

    [Fact]
    public void LoopRolesAreTheFiveRolesInLoopOrder()
    {
        var company = CompanyDefinition.Load(Root);
        Assert.Equal(["Orchestrator", "Planner", "Maker", "Checker", "Reflector"], company.Roles.Select(r => r.Name));
    }

    [Fact]
    public async Task MafDiscoversEverySkillFolderInThePluginMarketplace()
    {
        var company = CompanyDefinition.Load(Root);
        var expected = company.SkillDirectories
            .SelectMany(d => Directory.GetDirectories(d))
            .Where(d => File.Exists(Path.Combine(d, "SKILL.md")))
            .Select(d => Path.GetFileName(d))
            .Order(StringComparer.Ordinal)
            .ToList();

        using var source = new AgentFileSkillsSource(company.SkillDirectories, scriptRunner: null);
        var agent = new ChatClientAgent(new NoChatClient(), name: "probe");
        var skills = await source.GetSkillsAsync(new AgentSkillsSourceContext(agent, null), CancellationToken.None);
        var loaded = skills.Select(s => s.Frontmatter.Name).Order(StringComparer.Ordinal).ToList();

        Assert.NotEmpty(expected);
        Assert.Equal(expected, loaded);
    }

    [Fact]
    public void ClaudeHooksAreArraysAsClaudeCodeRequires()
    {
        foreach (var rel in new[] { ".claude/settings.json", "plugins/pmcro/hooks/hooks.json" })
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(Path.Combine(Root, rel)));
            var pre = doc.RootElement.GetProperty("hooks").GetProperty("PreToolUse");
            Assert.True(pre.ValueKind == JsonValueKind.Array, $"{rel}: hooks.PreToolUse must be an array, was {pre.ValueKind}");
        }
    }

    [Theory]
    [InlineData(false, 2)] // must-fail: no open trail blocks the edit
    [InlineData(true, 0)]
    public void LogBeforeActHookBlocksEditsWithoutAnOpenTrail(bool openTrail, int expectedExit)
    {
        var trails = Directory.CreateTempSubdirectory("pmcro-trails-");
        try
        {
            if (openTrail)
            {
                var t = Directory.CreateDirectory(Path.Combine(trails.FullName, "0001-probe"));
                File.WriteAllText(Path.Combine(t.FullName, "00-frame.jsonl"), "{}\n");
            }

            var script = Path.Combine(Root, "plugins", "pmcro", "skills", "frame", "scripts", "require-open-trail.ps1");
            var psi = new ProcessStartInfo(OperatingSystem.IsWindows() ? "pwsh.exe" : "pwsh")
            {
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                WorkingDirectory = Root,
            };
            foreach (var a in new[] { "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", script, "-TrailsDir", trails.FullName })
            {
                psi.ArgumentList.Add(a);
            }

            using var p = Process.Start(psi)!;
            p.WaitForExit(30_000);
            Assert.Equal(expectedExit, p.ExitCode);
        }
        finally
        {
            trails.Delete(recursive: true);
        }
    }

    private sealed class NoChatClient : IChatClient
    {
        public Task<ChatResponse> GetResponseAsync(IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default) =>
            throw new NotSupportedException("Skill discovery never calls the model.");

        public IAsyncEnumerable<ChatResponseUpdate> GetStreamingResponseAsync(IEnumerable<ChatMessage> messages, ChatOptions? options = null, CancellationToken cancellationToken = default) =>
            throw new NotSupportedException("Skill discovery never calls the model.");

        public object? GetService(Type serviceType, object? serviceKey = null) => null;

        public void Dispose()
        {
        }
    }
}
