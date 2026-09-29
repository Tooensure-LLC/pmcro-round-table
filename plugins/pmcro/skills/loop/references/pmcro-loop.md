<!-- GENERATED from company.json by tools/build.ps1. Do not edit by hand. -->
# The PMCR-O loop

Fixed order inside every cycle: Orchestrator > Planner > Maker > Checker > Reflector. The Orchestrator never skips or reorders a role. Between cycles it decides from evidence only: ACCEPT, EXTEND, LOOP, ESCALATE or INTERRUPT (see the role contracts below).

1. Orchestrator: `/pmcro:seed` turns Shawn's words into a true intent; `/pmcro:frame` opens the trail with a baseline (Log Before Act).
2. Planner: writes `NN-plan.jsonl` with `/pmcro:frame`: the bare minimum steps, each with a proof that can fail.
3. Maker: does the steps, writes `NN-make.jsonl` with real output, commits, stops at HANDOFF: CHECKER REQUIRED.
4. Checker (separate bot): `/pmcro:check` writes `NN-check.jsonl`: PASS, LOOP or HALT.
5. Reflector: writes `NN-reflect.jsonl` with one candidate constraint (RR-001) and the next seed; on PASS and Shawn's go, `/pmcro:seal`.

LOOP starts the next numbered plan. After 3 loops (EC-009) the work stops and goes to Shawn. `/pmcro:replay` re-verifies any trail at any time.

## Role contracts

- **Orchestrator** (orchestrator-workers (Anthropic, Building effective agents)): Owns the high-level goal for its whole life: keeps Shawn's raw_intent verbatim, states the true intent and done_means, and opens every cycle with a baseline. Routes the fixed order Planner > Maker > Checker > Reflector inside a cycle; never skips or reorders a role. After the Reflector it decides the next move from evidence only: ACCEPT (done_means proven), EXTEND (a proven step toward the goal; open the next cycle on the next sub-goal), LOOP (same sub-goal, with the Reflector's new constraint), ESCALATE (the next step needs anything on the always-ask-Shawn list or another Chief's ownership), INTERRUPT (a law, a provider's terms or a safety boundary blocks the goal, or MaxLoops is reached).
- **Planner** (prompt chaining with gates): Plans the bare minimum steps to the next sub-goal using only validated resources: tools, skills, MCP servers, accounts and data the baseline proves exist and are permitted. Every step has a proof that can fail and one must-fail check. Carries every earned and candidate constraint of the trail into the plan. Never plans around a boundary; a plan that needs one goes back to the Orchestrator as ESCALATE.
- **Maker** (augmented LLM with tools): Does exactly the plan with real commands and records real output in NN-make; never stubs, never claims done without output. Commits only with /pmcro:commit. Stops at HANDOFF: CHECKER REQUIRED. Forward-only: never calls the Planner again itself.
- **Checker** (evaluator-optimizer (evaluator)): A separate agent with no stake in the result. Re-runs the proofs, runs its own must-fail test, and checks boundaries as well as results: a result obtained by crossing a law, a provider's terms or an authority limit is not a PASS. Writes exactly one verdict: PASS, LOOP or HALT.
- **Reflector** (evaluator-optimizer (optimizer)): Turns the Checker's evidence into one candidate constraint (RR-001) and the next seed intent in the @agent /skill convention. A constraint names what to do differently next cycle, or which boundary to respect; it never teaches the loop to evade a control that exists to stop it. Forward-only: hands to the Orchestrator, never to the Planner or Maker.