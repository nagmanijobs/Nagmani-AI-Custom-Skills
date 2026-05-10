# Copilot Skill Prompt Examples

This file contains standard prompts to effectively invoke the skills in this repository.

## GitHub Actions Triage Skill

Use these prompts to trigger the `github-actions-triage` skill when you need to diagnose and fix CI failures.

### Quick Triage (Minimal Input)
```
Triage this GitHub Actions failure and give root cause and minimal fix
```

### With Run Details
```
CI is red on this run: https://github.com/nagmanijobs/repo-name/actions/runs/12345678
Failed job: Build and test on Node.js 20
Error: npm ERR! code ERESOLVE

Classify failure type and propose safest remediation.
```

### Flaky Test Investigation
```
This test fails intermittently in CI but passes locally.
Job: test-suite
Error excerpt: ECONNREFUSED at spec/integration.test.js:42

Analyze failure classification and suggest deterministic fix or retry strategy.
```

### Deployment Pipeline Failure
```
Deploy job failed on main branch after commit abc1234
Pipeline stage: Deploy to QA
Error: Artifact not found in build-artifacts/

Root cause analysis and minimal fix plan with validation steps.
```

### Emergency Triage (Red CI, Multiple Failures)
```
CI is broken on main. Multiple jobs failing:
- Build: Node version mismatch
- Tests: Timeout after 30s
- Lint: New rules violation

Root cause for each, prevent cascading errors, give fix priority.
```

## Prompt Structure for Best Results

Each prompt should ideally include:

1. **Context**: What failed (workflow, job, step)
2. **Evidence**: Error message or log excerpt
3. **Scope**: Branch, commit SHA, or run URL
4. **Goal**: What you need (root cause, fix plan, validation)

### Example Template
```
[Failure Context]
Workflow: CI - run tests
Failed Job: Build and test on Node.js 18
Branch: main

[Evidence]
Error: ENOENT: no such file or directory, open 'dist/index.js'
At step: Run build checks

[Request]
Root cause in one sentence, minimal fix plan, and validation steps.
```

## Common Triggers for This Skill

These phrases will likely invoke the github-actions-triage skill:

- "Triage this GitHub Actions failure"
- "CI is red, analyze and propose fix"
- "Root cause analysis for failed workflow"
- "Debug workflow failure and suggest fix"
- "Classify CI failure type"
- "GitHub Actions test failure analysis"
- "Workflow job failed, fix plan"

## Output Format You'll Get

The skill returns:

- **Root cause**: One sentence explaining the failure
- **Evidence**: Key log lines or conditions proving it
- **Fix plan**: Minimal code/config changes
- **Validation plan**: Exact checks and rerun scope
- **Prevention**: One to three hardening actions
