# open-problem-agent

An experiment: an AI agent (Claude Opus 5.5, medium effort) runs in GitHub Actions around the clock, picks
obscure open math problems, checks the literature, proves results in Lean 4 + Mathlib and writes them up.

A paper is published to Zenodo only if all gates pass (`scripts/finish.sh`):
1. Lean: the module builds, no banned constructs, main theorem uses only `propext`, `Classical.choice`,
   `Quot.sound` (`scripts/gate.sh`).
2. LaTeX builds.
3. A separate, fresh reviewer session (`REVIEW_PROMPT.md`) confirms: Lean statement = paper claim, problem
   listed as open, no prior solution found, proof sound, AI authorship disclosed.

Everything here is AI-generated. No human checks the proofs by hand.

Layout: `PROMPT.md` (research agent), `STATE.md` (its memory), `Research/` (Lean), `papers/<slug>/`.
Secrets: `CLAUDE_TOKEN_ALEX|SEEL|KILI` (from `claude setup-token`), `ZENODO_TOKEN`.
Selftest without secrets: run the workflow manually with `selftest = true`.
