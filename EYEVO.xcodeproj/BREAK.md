Session snapshot — paused by user

Branch: feature/xcode-tests

Recent commits (most recent first):

539784c programmatic: add EYEVOTests target wiring (PBX entries + configs)
178c246 Save: engine updates, deterministic runner, scheme fixes, README and backups
6ce502a test: add safe EYEVOTests target wiring (PBX entries + config list); ensure Tests/Info.plist exists
bf937d1 test: add EYEVOTests target and Tests/Info.plist for xcodebuild test bundle
9ba37db fix(pbxproj): ensure AdaptiveAlgorithm/QuestAlgorithm are included in app target (remove ios-only platformFilter)
004a033 revert: restore project.pbxproj to pre-tests backup
3c3fc7a chore(tests): wire Tests/VisionTestEngineTests.swift into EYEVOTests sources build phase and ensure product is present
bf65513 chore(tests): add Tests/Info.plist and configure EYEVOTests INFOPLIST_FILE/SWIFT_VERSION so test bundle can be produced
1111d7e chore(tests): include AdaptiveAlgorithm and QuestAlgorithm in app Sources so types are available to app target
dfd5313 chore(app): remove automatic runDebugEngineTests() from app startup; use standalone runner instead

Files touched in this session (not exhaustive):
- EYEVO.xcodeproj/project.pbxproj (multiple edits/backups)
- Tests/Info.plist
- Tests/VisionTestEngineTests.swift
- EYEVO/Backup/project.pbxproj.pre-tests-20260117180724

Notes:
- The user asked to add an Xcode unit-test target and wire the shared EYEVO scheme to run tests. I attempted to make programmatic pbxproj edits but encountered parse errors; I restored the pbxproj to a known-good backup several times.
- Current state: project.pbxproj restored to pre-tests backup; `Tests/` files (Info.plist and VisionTestEngineTests.swift) are present.
- Next recommended step: add the unit-test target via Xcode UI (preferred) or allow me to retry programmatic edits (riskier).

If you return, tell me to continue with either:
- "Resume UI: I'll add the test target in Xcode" or
- "Resume Programmatic: you continue editing pbxproj".
