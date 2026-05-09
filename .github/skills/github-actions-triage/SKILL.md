---
name: github-actions-triage
description: "Use when: GitHub Actions workflow fails, CI is red, tests fail in pipeline, lint/build job fails, or you need root-cause analysis and a safe fix plan."
---

# GitHub Actions Triage

## Purpose
This skill helps investigate and resolve failed GitHub Actions runs with a consistent, low-risk workflow.

## Use When
- A workflow run failed and you need quick root-cause analysis.
- CI is flaky and you need reproducible debugging steps.
- A specific job (test/lint/build/deploy) fails and you need a minimal fix plan.
- You want a clean incident summary to post in PR comments or team chat.

## Inputs To Gather
- Workflow name and run URL (or run ID)
- Failed job and step name
- Error log excerpt (first error + final stack trace)
- Commit SHA and branch
- Any recent dependency/version/config changes

## Triage Workflow
1. Identify the first real failure (ignore cascading errors).
2. Classify failure type:
   - Environment/configuration
   - Dependency/version drift
   - Test regression
   - Build/lint/typecheck issue
   - External service/transient failure
3. Reproduce locally when possible.
4. Propose the smallest safe fix.
5. Define validation:
   - local command(s)
   - rerun failed job
   - full workflow rerun if needed
6. Capture prevention actions (pin versions, retries, caching, alerts, ownership).

## Output Format
- Root cause: one sentence.
- Evidence: key log lines or conditions that prove it.
- Fix plan: minimal code/config changes.
- Validation plan: exact checks and rerun scope.
- Prevention: one to three hardening actions.

## Guardrails
- Prefer deterministic fixes over blanket retries.
- Do not disable tests/checks as a first response.
- Keep blast radius small; avoid unrelated refactors.
- If cause is uncertain, provide top two hypotheses with tests to disambiguate.
