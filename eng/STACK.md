# PMCR-O stack

Rule (earned in this trail): every pin records its source and check date, and anything upstream does not mark stable is tagged PREVIEW or ALPHA. Re-check a pin before any upgrade. The MAF pin went stale one day after it was first written down.
The pins that actually take effect are `global.json` and `Directory.Packages.props`. This file explains them.

| Layer | Pin | Status | Source | Checked |
| --- | --- | --- | --- | --- |
| .NET SDK | 10.0.401 (`global.json`, rollForward latestFeature) | STABLE, LTS until 2028-11-14 | https://dotnet.microsoft.com/platform/support/policy/dotnet-core | 2026-09-29 |
| Aspire | 13.5.4 (AppHost SDK and templates) | STABLE | https://github.com/microsoft/aspire/releases/tag/v13.5.4 | 2026-09-29 |
| Microsoft.Agents.AI, .Workflows | 1.23.0 | STABLE (released 2026-09-28) | https://www.nuget.org/packages/Microsoft.Agents.AI | 2026-09-29 |
| Microsoft.Agents.AI.DevUI, .Hosting | 1.23.0-preview.260928.1 | PREVIEW | nuget.org | 2026-09-29 |
| Microsoft.Agents.AI.Hosting.OpenAI | 1.23.0-alpha.260928.1 | ALPHA | nuget.org | 2026-09-29 |
| ModelContextProtocol (C# SDK) | 2.2.0, spec 2026-07-28, Streamable HTTP only | STABLE | https://www.nuget.org/packages/ModelContextProtocol | 2026-09-29 |
| OllamaSharp / CommunityToolkit.Aspire.OllamaSharp | 5.4.30 / 13.5.0 | STABLE | nuget.org | 2026-09-29 |
| OpenTelemetry | 1.19.x (MAF 1.23 requires OpenTelemetry.Api >= 1.18) | STABLE | nuget.org | 2026-09-29 |
| OpenTelemetry GenAI semantic conventions | main of semantic-conventions-genai | DEVELOPMENT (no tagged release) | https://github.com/open-telemetry/semantic-conventions-genai | 2026-09-29 |
| Ollama (host) | 0.34.4, model `qwen3:8b` | STABLE (do not take 0.40.0-rc) | `ollama --version`, `/api/version` | 2026-09-29 |
| Cloud model | grok-4.7 | STABLE (2026-09-21) | https://x.ai/api | 2026-09-29 |
| DocFX | 2.81.0 (local tool, `dotnet-tools.json`) | STABLE | nuget.org | 2026-09-29 |
| Grok Bot | app build | BETA | https://docs.x.ai/grok-bot/teams-and-enterprises | 2026-09-29 |
| dotnet/skills (vendored maintainer skills) | ff66f963fb82 | upstream main | `.agents/skills/UPSTREAM.json` | 2026-09-29 |

## Decisions recorded in trails/0001-foundation

- This repo targets net10.0 LTS. The older pmcro-runtime targets net11 preview; it stays as it is and is not ported here.
- The runtime uses the host's Ollama through a `chat` connection string, not an Aspire Ollama container.
- Scripts run under PowerShell 7 (`pwsh`). See `.agents/skills/powershell-execution`.

## Open

- Canonical GitHub org: Tooensure-LLC or PMCRO-AI-Agent-Company (Shawn decides). No remote is set.
- The MAF CodeAct (Hyperlight) package is alpha and not used here.
