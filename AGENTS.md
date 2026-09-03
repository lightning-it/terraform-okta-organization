<!-- cspell:ignore litroc -->
# Lightning IT Engineering Agent Guide

## Scope and sources of truth

- Inspect the repository, its `README`, `CONTRIBUTING.md`, `.lit/` policy,
  workflows, tests, and build metadata before changing code.
- Preserve repository-specific behavior unless an approved ADR changes it.
- Files distributed by `lightning-it/shared-assets-lit` are centrally managed;
  change their canonical source and synchronize them instead of maintaining
  divergent downstream copies.
- Repository settings and protected environments are managed through
  `lightning-it/github-management-lit`.

## Engineering baseline

- Keep changes small, reviewable, deterministic, and covered by tests that
  exercise success and failure behavior.
- Validate external input, use explicit timeouts, and fail closed when security
  or policy evidence is malformed, missing, or stale.
- Apply least privilege to credentials, workflow permissions, environments,
  network access, and repository access.
- Never commit credentials or sensitive operational data. Avoid exposing them
  in logs, exceptions, fixtures, examples, or generated artifacts.
- Pin third-party GitHub Actions to immutable commit SHAs and pin build/runtime
  dependencies according to the repository's dependency policy.
- Preserve provenance: releases and deployments must be traceable to an exact
  commit, reviewed checks, and immutable artifacts.

## Required standards

- Use the repository's applicable Lightning IT Engineering ADRs as the
  decision record.
- Follow the OpenSSF Scorecard controls and OpenSSF Best Practices criteria
  applicable to the repository.
- Apply secure-development practices from NIST SSDF (SP 800-218), supply-chain
  controls from SLSA, and artifact signing/verification practices from Sigstore
  where the repository builds or publishes artifacts.
- Apply OWASP guidance relevant to the implementation, including secure
  defaults, dependency hygiene, input validation, and secret handling.

## Validation and review

- Execute every deterministic lint, format, type-check, test, build,
  packaging, policy, and validation command through the digest-pinned
  `scripts/wunder-devtools-ee.sh` boundary. The host supplies only Git, the
  supported container engine, and the managed Devtools, push-ready, and
  pre-commit dispatchers. A dispatcher may inspect Git state and start the
  pinned container; it may not run a repository validator on the host.
- Host Python, Node.js, Ansible, Ruff, Python type checkers, markdownlint,
  Renovate, and other repository validators are never valid acceptance
  evidence. If a command or
  compatible version is missing, fail closed and update/release the Devtools
  image plus its centrally managed digest; never fall back to a host runtime,
  ad-hoc virtual environment, or unpinned helper image.
- Keep the Devtools defaults read-only, offline, socket-free,
  capability-dropped, and non-privileged. Grant a gate only its explicitly
  tested minimum. Linked-worktree Git metadata is read-only; container Git may
  trust only `/workspace`, never `*`. Use the isolated container home for
  executable temporary fixtures and keep generic `/tmp` non-executable.

- Run `python3 scripts/lit-push-ready.py push-ready` before pushing when the
  script is present. It runs only deterministic checks and MUST NOT invoke
  Codex, GitHub Copilot, another model, or any external AI endpoint. This
  evidence-producing command requires a clean, committed `HEAD`; use the
  deterministic `review` command while iterating on uncommitted changes.
- Local evidence is developer-controlled. The authoritative current-head
  review gate and required GitHub checks remain mandatory. Human,
  community, and unknown-automation PRs require an actual Copilot review of the
  current head. Only explicitly allowlisted Renovate and shared-assets changes
  may satisfy that gate through a documented deterministic, evidence-bound
  exception; unknown bots fail closed.
- Automated GitHub Copilot requests funded by Lightning IT are restricted to
  pull requests whose exact author login is `litroc`. Every other human or
  external contributor must supply a valid current-head review under their own
  entitlement; Lightning IT automation verifies that review but never requests
  or funds it. Personal tokens and personal provider keys never enter Actions.
- Every exact same-repository PR authored by
  `lightning-it-release-automation[bot]` uses only the ADR-defined, protected
  MLX-90 §7.2 Exact-Revision Codex review. No deterministic release exemption
  and no GitHub Copilot fallback is permitted. The review binds the live base,
  head, unique merge base, integration tree, and SHA-256 of the complete binary
  Git-object diff. It MUST run from the protected base copy of
  `.github/workflows/release-bot-exact-head-review.yml`, receive no checkout,
  history, or credentials, and emit only the neutral `Current revision review`
  check on the exact head. It MUST never emit or synthesize the legacy
  `Successful Copilot review` check. The built-in `:read-only` permission
  profile technically denies
  writes and command network access. This path never applies to human,
  community, or other automation authors.
- A deterministic ancestry-backmerge retry MUST exhaustively read the open and
  closed pull-request history for its exact repository-owned branch, base and
  head before it creates a pull request. Any closed exact match, unexpected
  response shape, or ambiguous inventory fails before PR creation and before
  review dispatch. One already-open exact match may be identity- and
  revision-validated, but the controller MUST exit without redispatching AI or
  re-enabling a failed workflow path. Recovery after terminal evidence uses a
  fresh revision through the normal correction, promotion and backmerge chain;
  it never attaches the same commit to a successor PR.
- Run deterministic checks on the fetched authoritative base integration tree
  through the centrally pinned CI profile; do not reclassify an executable
  pipeline step as remote-only to make a local run pass.
- The local `review` command performs only deterministic exact-patch and
  secret-safety checks. AI review is a protected remote-only boundary: human
  PRs follow the author-specific GitHub review gate and Release-App PRs use
  only the §7.2 Exact-Revision Codex workflow above.
- An optional pre-push hook may call
  `python3 scripts/lit-push-ready.py pre-push --remote-name "$1" --remote-url "$2"`;
  Git's hook input binds every pushed ref to the saved evidence `HEAD` without
  invoking any local AI.
- Run the repository-specific lint, test, build, security, and packaging gates
  documented in `.lit/push-ready.json`, `CONTRIBUTING.md`, and CI.
- Treat `AGENTS.md` as the canonical Codex and Copilot contract.
- `.github/copilot-instructions.md` must contain the current managed
  `AGENTS_SHA256` binding.
- Resolve or explicitly disposition every automated-review finding against the
  current commit and rerun affected deterministic checks.
- Do not weaken a required check, branch rule, security control, or test merely
  to make a change pass.
- The protected human Copilot-request job must require `litroc` in its immutable
  job predicate and re-prove the live PR author as exactly `litroc` immediately
  before requesting review. External contributors never enter this
  organization-funded request path; they supply their own review entitlement.
- GitHub may expose one completed Copilot review through GraphQL before the REST
  review collection converges. After selecting and fully inspecting the exact
  current-head review through GraphQL, every REST cross-check must therefore
  use a bounded, read-only convergence wait bound to the same immutable review
  ID and head. That wait is deterministic verification, never an AI retry. A
  missing, duplicated, changed, or persistently invisible review fails closed.
- One current-revision evidence version MUST have one canonical expanded
  schema. A rollout helper may recognize an older shape only as an exact-keyset
  compatibility form bound to one named repository, the protected live base,
  one exact historical producer blob, same-repository author, review path,
  metadata revision, empty live label set, and an exact candidate manifest of
  path, Git blob, size, and change status. That manifest may authorize a
  replacement PR only when every changed file and every immutable head content
  response matches it exactly; added, removed, renamed, changed, symlinked, or
  extra content fails closed. This content-addressed cutover deliberately does
  not bind a moving PR number or commit SHA, so a byte-identical successor can
  finish after infrastructure failure without another policy exception. The
  helper MUST keep the expanded form strict, reject mixed or partial shapes,
  and make compatibility unreachable as soon as the protected producer blob is
  replaced; reusing one version label as a general schema alias is forbidden.
- The deterministic shared-assets sync exception is valid only when the
  protected organization Required Workflow verifies the successful
  `shared-assets-lit/main` source run and exact target matrix job, plus one
  issue comment created through GitHub by App ID `4351516`. That proof must
  bind the source SHA and run together with the target repository, PR, base
  SHA, head SHA, and tree SHA. Commit authors and trailers alone are
  insufficient; missing, duplicated, stale, or non-App evidence fails closed.

## Branch and change management

- Normal changes target `develop`; stable promotion to `main` uses a reviewed
  pull request unless a repository ADR explicitly defines another model.
- In the five-repository MLX-90 application allowlist, normal `develop` to
  `main` and other non-Security promotions require a current-head protected
  human environment approval. Only the exact evidence-bound MLX-90 Security
  path in the approved producer and consumer may use the reviewer-free
  authorization environment, and it must not bypass branch rules or required
  checks. Repositories outside that rollout retain their repository-specific
  human promotion policy.
- A Release-App promotion controller may dispatch the protected Exact-Revision
  review only in the workflow run that creates the immutable promotion PR.
  Schedule, push, or manual reconciliation of an already-open same-head PR
  MUST NOT redispatch AI. A failed single dispatch remains blocked and requires
  a fresh PR bound to a new head; it is never retried in place.
- During the one-time rollout, the protected human environment MUST exist and
  be audited before the bootstrap `develop` to `main` PR runs. The new check
  becomes required only after the byte-identical policy workflow and script
  are verified on `main`; no bootstrap may use a reviewer-free environment or
  ruleset bypass.
- Do not push directly to protected branches or bypass required checks.
- Temporary self-approval is permitted only where ADR-70 applies, must bind to
  the exact immutable SHA or saved plan, and must be recorded separately for
  each protected action.

<!-- LIT REP-60 review governance: start -->
<!-- cspell:ignore litroc -->

## REP-60 current-revision review governance

- Local validation is deterministic only. It must never invoke Codex, GitHub
  Copilot, another model, or an external AI endpoint. Authoritative AI review
  runs only in the protected GitHub pipeline and binds the exact PR head.
- Lightning IT automation may request and fund one GitHub Copilot review only
  when the exact PR author is `litroc`, and only at the finalization boundary;
  intermediate `synchronize` pushes must not trigger AI review. Any finding
  requires correction and a final current-head re-review. The request is
  consumed once per head; unavailable or quota-blocked reviews fail closed
  without an automatic retry. Organization-funded Codex remediation and its
  single re-review are likewise restricted to `litroc`.
- Every other human or external contributor supplies any required current-head
  Copilot review under their own entitlement and cost. Lightning IT verifies
  valid evidence but never requests or funds that review, and personal tokens or
  provider keys never enter Actions.
- A same-repository PR authored exactly by
  `lightning-it-release-automation[bot]` uses only the protected MLX-90 §7.2
  Exact-Revision Codex check. It must never request Copilot or synthesize a
  Copilot success.
- A proven ancestry-only main-to-develop backmerge uses the deterministic
  evidence-bound exemption and performs zero AI calls. Unknown automation
  identities fail closed.
- The only neutral merge-gate result is `Current revision review`. Missing,
  stale, ambiguous, or unresolved review evidence blocks the merge.

<!-- LIT REP-60 review governance: end -->

<!-- LIT REP-60 evidence lifecycle: start -->

### REP-60 evidence lifecycle (mandatory)

- Every pull request into `develop` retains its exact-final-head native GitHub
  CI, required-check, and review history as the authoritative evidence for
  acceptance into `develop`.
- A pull request into `develop` MUST NOT create or retain an additional durable
  release-evidence package, duplicate WORM artifact, or second AI-review
  evidence outside that native GitHub history.
- Only the protected `develop` to `main` promotion creates exactly one durable,
  complete release-evidence package. It binds the full integrated promotion
  diff, base, head, merge base, integration tree, policy, reviewer result, and
  all release and audit checks.
- Agents, workflows, and repository-local rules MUST NOT duplicate that durable
  evidence per `develop` pull request or invoke local AI to create evidence.
  Repository-local rules may only make this lifecycle stricter.

<!-- LIT REP-60 evidence lifecycle: end -->

<!-- LIT Devtools container governance: start -->

## Devtools container execution boundary

- Every deterministic lint, format, type-check, test, build, packaging,
  policy, and validation workload runs in the digest-pinned Lightning IT
  Devtools image, locally and in CI. Host-language runtimes never provide
  acceptance evidence.
- The host boundary is limited to Git, the supported container engine, and the
  centrally managed Devtools, push-ready, and pre-commit dispatchers. A
  dispatcher may inspect Git state and start the pinned container, but it must
  not execute a repository validator through host Python, Node.js, Ansible,
  Ruff, a Python type checker, markdownlint, Renovate, or a comparable host
  runtime.
- If a required command or compatible version is absent, fail closed. Add and
  pin it in `container-ee-wunder-devtools-ubi9`, release that image normally,
  update the centrally managed digest, and rerun the gate. Host fallbacks,
  ad-hoc virtual environments, and unpinned helper images are forbidden.
- Repository-owned tests derive the exact full Devtools image reference from
  the centrally managed push-ready engine when checking the installed wrapper;
  they never hard-code an independent release tag that can drift during a
  normal image rollout.
- A target-specific regression test that asserts managed Devtools-wrapper
  arguments is the same atomic managed unit as the wrapper. Both synchronize
  through an exact source binding, and only an explicitly digest-allowlisted
  predecessor may be replaced; unknown target test content fails closed.
- Defaults stay read-only, offline, socket-free, capability-dropped, and
  non-privileged. A gate may opt into only its explicit tested minimum. Linked
  Git metadata remains read-only and container Git may trust only
  `/workspace`, never `*`. Executable temporary fixtures use the isolated
  container home while generic `/tmp` remains non-executable.
- The Devtools boundary never makes local Codex, Copilot, or other model calls
  and never receives personal AI credentials.

<!-- LIT Devtools container governance: end -->

<!-- LIT AI task governance: start -->

## AI model and token governance

Apply `LIT-GEN-GDR-GOV-30-Budget-Conscious-AI-Model-Selection` to every
substantive Codex or ChatGPT-assisted task. Before investigation, planning, tool
use, implementation, or delegation, record a compact task profile in the task
chat: work item, risk (`low`, `normal`, or `high`), smallest sufficient
model/reasoning choice, rationale, and a concrete escalation condition.

- Use the balanced, lowest reliable capability by default. Escalate to a
  premium/frontier model or higher reasoning only for a high-risk decision,
  complex architecture/debugging/dependencies, or a documented focused failure
  of the standard approach. Restrict that escalation to the difficult subtask.
- Never use Speed Mode. Do not replace verification with a more expensive model
  or sacrifice quality to reduce elapsed time.
- Retrieve only relevant issue, files, logs, and source records; avoid broad
  repository or chat-history loading, speculative analysis, and unbounded retry
  loops. Delegate only independent, bounded work that reduces total effort.
- For GitHub or Jira work, include the task profile in the issue/task record
  when AI assistance materially affects execution. Close with verification and
  remaining risks; preserve durable decisions in Confluence, Jira, or GitHub.

<!-- LIT AI task governance: end -->
