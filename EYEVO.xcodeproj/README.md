EYEVO
=====

A compact Swift vision-screening prototype (EYEVO) with a small engine for adaptive visual acuity testing and a SwiftUI front end. This repository includes a lightweight standalone test runner to validate core engine behavior without requiring Xcode test wiring.

This README includes:
- Quick start: build & run the standalone test runner
- Project layout
- How to run the app (macOS / iOS) at a high level
- Guidance and suggested wording to help produce documentation for awards and EB-1A style evidence (informational only — not legal advice)

Quick start (standalone test runner)
-----------------------------------
The easiest way to run the core engine checks is to compile the small test harness included under `Tools/engine_test_runner.swift` together with the engine source files.

From the repository root (bash):

```bash
# compile the runner together with engine sources and algorithm files
swiftc -o /tmp/eyevo_engine_test_runner \
  Tools/engine_test_runner.swift \
  VisionTestEngine.swift \
  VisionTestSession.swift \
  VisionCoreModels.swift \
  AdaptiveAlgorithm.swift \
  QuestAlgorithm.swift

# execute
/tmp/eyevo_engine_test_runner
```

You should see console output of the engine debug logs and the test assertion results, e.g. "Summary: 7 passed, 0 failed".

Project layout
--------------
- `EYEVO/` - Xcode app bundle skeleton (assets, app files)
- `VisionTestEngine.swift` - Core engine logic (adaptive testing, session lifecycle)
- `VisionTestSession.swift` - Session state container
- `VisionCoreModels.swift` - Shared model enums/structs
- `AdaptiveAlgorithm.swift`, `QuestAlgorithm.swift` - Pluggable algorithms used by the engine
- `Tools/engine_test_runner.swift` - Standalone runner for quick validation
- `Tests/` - XCTest files (not currently wired to an Xcode test target in this repo)

Running the full app
--------------------
This repo contains an Xcode project (`EYEVO.xcodeproj`). You can open it in Xcode to run the app on macOS or iOS simulators.

Notes on tests and Xcode
-----------------------
- The repo currently includes `Tests/VisionTestEngineTests.swift`, but the Xcode scheme in this copy may not have a test action configured. The standalone runner is provided to validate logic quickly.
- If you want me to add a proper unit test target and a shared scheme so that `xcodebuild -scheme EYEVO test` runs your XCTest suite, I can do that for you on a branch (I will back up and commit changes).

Evidence & Wording Guidance for Awards or EB-1A-style documentation (informational)
---------------------------------------------------------------------------------
What this section is: a practical, non-legal set of suggestions to help you collect and present evidence that demonstrates originality, impact, and leadership when applying for awards or preparing immigration documentation (e.g., EB-1A). This does not constitute legal advice — consult an immigration attorney or awards committee guidelines for requirements specific to your case.

1) Collect the right artifacts
- Code repository (this project) — commit history showing you are the principal author. Point to important commits and PRs that implement the key ideas.
- Technical writeups: README, short design notes, or a preprint describing the approach and algorithmic contribution.
- Publications: conference papers, journal articles that cite or incorporate the work.
- Presentations: slides, videos of talks, invited talks, keynote appearances.
- External recognition: adoption by other projects, integration into products, citations, press coverage, or awards.
- Patents: filed/granted patents describing novel ideas used by the project.

2) Metrics that matter
- Citations (papers), forks and stars (GitHub) if public, downloads or installs, demo usage statistics, or integration in other projects.
- Invited talks and review panels where you presented the work.
- Letters of support from independent experts who can attest to the novelty and impact.

3) Safe, award-oriented wording you can reuse in documentation or a short project blurb
(Use short, factual statements — insert project-specific details where shown.)

- Short project description (100–200 words):

"EYEVO is a vision-screening prototype implementing an adaptive visual-acuity test engine that combines staircase and QUEST-like updates to select optotype sizes and measure acuity efficiently. The engine is designed to be small, auditable, and reproducible; it supports both tumbling-E and Sloan-letter stimuli and produces final acuity estimates and confidence metrics. The implementation and standalone test harness demonstrate correctness and robustness for the core adaptive logic."

- Suggested bullet points for an accomplishments list (each bullet should be backed by an artifact):
  - "Designed and implemented an adaptive visual-acuity engine (EYEVO) that decreased the number of trials required to reach a target confidence by X% compared to baseline algorithms (benchmarked in internal tests)."
  - "Authored a reproducible test harness and suite validating key behaviors (startSession, adaptive step updates, reversal detection) with passing checks."
  - "Presented the approach at [Conference/Workshop, Year] (slides/video available)."
  - "Filed a patent / submitted a manuscript / received [award name] for the method [provide link or registration number]."

- Example language for a letter of support (technical tone):

"The EYEVO project demonstrates a novel, efficient method for adaptive visual acuity estimation. Its algorithmic contributions — specifically the hybrid staircase/QUEST update and robust phase control — provide improved trial efficiency while preserving estimation accuracy. The codebase, test harness, and artifacts supplied by Dr. [Your Name] enabled independent verification and adoption in pilot studies, demonstrating both scientific novelty and practical impact." 

4) How to present evidence in a README or a dossier
- Add a short "Contributions & Impact" section that enumerates:
  - What is novel (one or two sentences)
  - Demonstrated outcomes (benchmarks, trials, citations)
  - Links to artifacts (papers, slides, demo videos, patents)
- Keep the phrasing factual and link to independent sources where possible (press articles, external repos, adoption examples).

5) Practical checklist for building an EB-1A/award dossier (non-legal)
- Gather all artifacts and timestamps (commits, DOIs, acceptance letters).
- Collect quantitative metrics (stars, forks, citations, downloads) and qualitative evidence (letters, invited talks).
- Draft concise, factual statements about the contribution, impact, and recognition.
- Ask 2–4 independent experts for short letters describing the importance of the work.
- Consult an immigration attorney (or awards committee) for exact criteria and how best to present the evidence.

Contributions & Impact — concise paragraph (dossier-ready)
---------------------------------------------------------

Use the paragraph below in application materials (CV, statements, or dossier) — replace bracketed placeholders with concrete facts/links. This phrasing is intentionally factual, measurable where possible, and avoids legal or subjective claims.

"EYEVO is an adaptive visual-acuity screening prototype implementing a hybrid staircase and QUEST-inspired adaptive update to select optotype sizes efficiently across test phases (gatekeeper → tumbling E → Sloan letters). I led the design and implementation of the core engine, authored a reproducible test harness used to verify core behaviors (startSession, adaptive size updates, reversal detection), and provided modular algorithm interfaces (staircase, QUEST, and pluggable strategies) to enable independent validation. Pilot benchmarking (internal dataset, N=[Y]) shows a median reduction of [X%] in required trials to reach target estimation confidence compared to a baseline staircase; artifacts and logs are provided in the dossier (repo: [REPO_URL], commit: [COMMIT_HASH])."

EB-1A/Award-safe language checklist
-----------------------------------
- Use verifiable facts (dates, commit hashes, DOIs, conference names).
- Prefer neutral verbs: "implemented", "authored", "designed", "validated", "presented".
- Quantify when you can and include measurement methodology references.
- Avoid legal or immigration-specific guarantees (this is informational only).

Suggested short snippets for different uses (copy/paste and fill placeholders)
- CV bullet:
  "Implemented EYEVO, an adaptive visual-acuity engine with a hybrid staircase/QUEST update; produced a reproducible test harness and validation logs (repo: [URL], commit: [HASH])."

- Conference / talk blurb:
  "Presented 'EYEVO: Efficient adaptive visual-acuity screening' at [Conference Name, Month Year]; slides and recording are available at [URL]."

- Evidence statement for dossier:
  "The code repository (link + commit hash), test logs (Tools/engine_test_runner output), and benchmark report (link) document the method and show reproducible verification of the core algorithmic claims."

Letter of support template (technical)
--------------------------------------

[Suggested structure for an independent letter writer — provide this as a starting point for reviewers.]

Dear [Committee/Officer],

I am writing to support the contribution of Dr. [Name] in developing the EYEVO adaptive visual-acuity engine. I have reviewed the implementation and test artifacts (repository: [REPO_URL], commit [COMMIT_HASH]) and confirm that the approach combines a controlled hybrid staircase/QUEST update with robust phase management to reduce the number of trials required while maintaining estimation fidelity in pilot evaluations. The codebase and standalone test harness allowed independent reproduction of the core behaviors described by Dr. [Name]. Based on my technical assessment, I consider the work to be a novel and practically useful contribution to low-cost visual screening methods.

Sincerely,
[Reviewer Name, Title, Institution]


Requirements coverage (how this README helps)
- Reproducibility: provides a reproducible test runner and commands to run it. (Done)
- Demonstration: points to artifacts to demonstrate contribution and impact and offers sample wording. (Done)
- Next steps / automation: suggests adding an Xcode test target or a CI workflow, both of which I can implement. (Optional)

If you want a customized snippet
- I can add a short "Contributions & Impact" section directly to `README.md` that includes quantified outcomes you provide (benchmarks, papers, dates) and will format it for copying into a dossier or cover letter. Tell me the specific numbers (benchmarks, talk/paper titles, dates) and I will insert them.

Want me to also:
- [ ] Add the Xcode unit test target + shared scheme and run `xcodebuild test` (I will backup pbxproj and commit on a branch)
- [ ] Create a one-page "evidence summary" file (`EVIDENCE.md`) with links and suggested letters (template)
- [x] Provide the README with run commands and EB-1A/award wording guidance (done)

Which of the optional follow-ups should I do next? If you want a tailored "Contributions & Impact" paragraph for the README or a template evidence summary for EB-1A, tell me the exact details you want included (conference/paper names, dates, any quantitative numbers) and I'll create them and commit to the repo.
