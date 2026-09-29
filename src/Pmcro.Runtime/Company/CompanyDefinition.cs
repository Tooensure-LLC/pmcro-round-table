using System.Text.Json;

namespace Pmcro.Runtime.Company;

/// <summary>A company seat (a Chief, a Checker or the Auditor) as declared in <c>company.json</c>.</summary>
/// <param name="Id">Stable seat id, also the agent name (for example <c>cto</c>).</param>
/// <param name="Title">Human title (for example <c>CTO Chief</c>).</param>
/// <param name="Instructions">The generated seat prompt from <c>chiefs/&lt;id&gt;/AGENT.md</c>; the same text a Grok Bot seat uses.</param>
public sealed record Seat(string Id, string Title, string Instructions);

/// <summary>A PMCR-O loop role and its contract, as declared in <c>company.json</c> <c>roles</c>.</summary>
public sealed record LoopRole(string Id, string Name, string Pattern, string Contract);

/// <summary>
/// The company, loaded from the repository's single source of truth (<c>company.json</c>) and the files
/// <c>tools/build.ps1</c> generates from it. Nothing here is hand-written configuration: change the company by
/// editing <c>company.json</c> and rebuilding.
/// </summary>
public sealed class CompanyDefinition
{
    private CompanyDefinition(string repoRoot, string name, IReadOnlyList<Seat> seats, IReadOnlyList<LoopRole> roles, IReadOnlyList<string> skillDirectories)
    {
        RepoRoot = repoRoot;
        Name = name;
        Seats = seats;
        Roles = roles;
        SkillDirectories = skillDirectories;
    }

    /// <summary>Absolute path of the repository root (the folder that holds <c>company.json</c>).</summary>
    public string RepoRoot { get; }

    /// <summary>Company display name.</summary>
    public string Name { get; }

    /// <summary>Every seat, in <c>company.json</c> order.</summary>
    public IReadOnlyList<Seat> Seats { get; }

    /// <summary>The five loop roles, in loop order.</summary>
    public IReadOnlyList<LoopRole> Roles { get; }

    /// <summary>Every <c>plugins/*/skills</c> folder: the Agent Skills shared with Claude Code, Codex, Cursor and Grok Bot.</summary>
    public IReadOnlyList<string> SkillDirectories { get; }

    /// <summary>Loads the company from <paramref name="repoRoot"/>.</summary>
    /// <exception cref="FileNotFoundException">A seat prompt was not generated; run <c>tools/build.ps1</c>.</exception>
    public static CompanyDefinition Load(string repoRoot)
    {
        var root = Path.GetFullPath(repoRoot);
        using var doc = JsonDocument.Parse(File.ReadAllText(Path.Combine(root, "company.json")));
        var c = doc.RootElement;

        var seats = new List<Seat>();
        foreach (var bot in c.GetProperty("bots").EnumerateArray())
        {
            var id = bot.GetProperty("id").GetString()!;
            var prompt = Path.Combine(root, "chiefs", id, "AGENT.md");
            if (!File.Exists(prompt))
            {
                throw new FileNotFoundException($"Seat prompt for '{id}' is missing; run tools/build.ps1.", prompt);
            }

            seats.Add(new Seat(id, bot.GetProperty("title").GetString()!, File.ReadAllText(prompt)));
        }

        var roles = c.GetProperty("roles").EnumerateArray()
            .Select(r => new LoopRole(
                r.GetProperty("id").GetString()!,
                r.GetProperty("name").GetString()!,
                r.GetProperty("pattern").GetString()!,
                r.GetProperty("contract").GetString()!))
            .ToList();

        var pluginRoot = Path.Combine(root, "plugins");
        var skillDirs = Directory.Exists(pluginRoot)
            ? Directory.GetDirectories(pluginRoot)
                .Select(p => Path.Combine(p, "skills"))
                .Where(Directory.Exists)
                .Order(StringComparer.Ordinal)
                .ToList()
            : [];

        return new CompanyDefinition(root, c.GetProperty("company").GetString()!, seats, roles, skillDirs);
    }

    /// <summary>Walks up from <paramref name="start"/> to the first folder that contains <c>company.json</c>.</summary>
    /// <exception cref="DirectoryNotFoundException">No ancestor holds <c>company.json</c>.</exception>
    public static string FindRepoRoot(string start)
    {
        for (var dir = new DirectoryInfo(Path.GetFullPath(start)); dir is not null; dir = dir.Parent)
        {
            if (File.Exists(Path.Combine(dir.FullName, "company.json")))
            {
                return dir.FullName;
            }
        }

        throw new DirectoryNotFoundException($"No company.json found above '{start}'. Set Pmcro:RepoRoot.");
    }
}
