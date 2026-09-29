// Pmcro.Runtime: the company's own host for the same seats and skills that run in Grok Bot and Claude Code.
// Started from the Microsoft.Agents.AI.ProjectTemplates "aiagent-webapi" template (provider: ollama); the sample
// writer/editor agents were replaced by agents declared in company.json.
using Microsoft.Agents.AI;
using Microsoft.Agents.AI.DevUI;
using Microsoft.Agents.AI.Hosting;
using Microsoft.Agents.AI.Workflows;
using Microsoft.Extensions.AI;
using Pmcro.Runtime.Company;

var builder = WebApplication.CreateBuilder(args);
builder.AddServiceDefaults();

// Local-first model: the "chat" connection string comes from the AppHost (host Ollama, pinned in eng/STACK.md).
builder.AddOllamaApiClient("chat").AddChatClient();

var company = CompanyDefinition.Load(
    builder.Configuration["Pmcro:RepoRoot"] ?? CompanyDefinition.FindRepoRoot(builder.Environment.ContentRootPath));
builder.Services.AddSingleton(company);

// One skills provider over every plugins/*/skills folder. No script runner is passed on purpose: agents can
// advertise, load and read skills, but scripts run only through a governed Maker step (SubprocessScriptRunner is
// documented by Microsoft as demonstration-only).
builder.Services.AddSingleton(_ => new AgentSkillsProvider(company.SkillDirectories));

AIAgent NewAgent(IServiceProvider sp, string name, string description, string instructions) =>
    new ChatClientAgent(
        sp.GetRequiredService<IChatClient>(),
        new ChatClientAgentOptions
        {
            Name = name,
            Description = description,
            ChatOptions = new() { Instructions = instructions },
            AIContextProviders = [sp.GetRequiredService<AgentSkillsProvider>()],
        });

// Seats: the same generated prompt a Grok Bot seat uses (chiefs/<id>/AGENT.md).
foreach (var seat in company.Seats)
{
    builder.AddAIAgent(seat.Id, (sp, key) => NewAgent(sp, key, seat.Title, seat.Instructions));
}

// Loop roles: contracts from company.json roles.
foreach (var role in company.Roles)
{
    builder.AddAIAgent($"role-{role.Id}", (sp, key) => NewAgent(sp, key, role.Name, role.Contract));
}

// One PMCR-O cycle inside a governed run: Planner > Maker > Checker > Reflector, in fixed order (forward-only).
// The Orchestrator is the caller that opens the cycle and decides ACCEPT/EXTEND/LOOP/ESCALATE/INTERRUPT afterwards.
builder.AddWorkflow("pmcro-cycle", (sp, key) => AgentWorkflowBuilder.BuildSequential(
    workflowName: key,
    agents:
    [
        sp.GetRequiredKeyedService<AIAgent>("role-planner"),
        sp.GetRequiredKeyedService<AIAgent>("role-maker"),
        sp.GetRequiredKeyedService<AIAgent>("role-checker"),
        sp.GetRequiredKeyedService<AIAgent>("role-reflector"),
    ])).AddAsAIAgent("pmcro-cycle-agent");

// OpenAI Responses/Conversations endpoints (also required by DevUI).
builder.Services.AddOpenAIResponses();
builder.Services.AddOpenAIConversations();

var app = builder.Build();
app.UseHttpsRedirection();
app.MapOpenAIResponses();
app.MapOpenAIConversations();
app.MapDefaultEndpoints();

if (app.Environment.IsDevelopment())
{
    app.MapDevUI();
}

app.Run();
