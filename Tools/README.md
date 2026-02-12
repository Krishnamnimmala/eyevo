# Staircase Simulator

This simulator runs the `StaircaseAlgorithm` deterministically to exercise the 2-down/1-up staircase and observe internal state.

How to compile and run (macOS / developer machine):

1. Compile the simulator with the project's core engine sources:

```bash
swiftc -o /tmp/stairs_sim \
    ../VisionCoreModels.swift \
    ../Optotype.swift \
    ../VisionTestSession.swift \
    ../AdaptiveAlgorithm.swift \
    ../VisionTestEngine.swift \
    ../TelemetryManager.swift \
    staircase_simulator.swift
```

2. Run the simulator with optional environment variables:

- `STAIRCASE_VERBOSE=1` — enable per-trial verbose logging from the Staircase algorithm.
- `STAIRCASE_STEP=<double>` — override default step size (e.g. `0.08`).
- `STAIRCASE_REVERSALS=<int>` — override reversal stopping threshold (e.g. `5`).

Example run that uses a smaller step for finer acuity moves and verbose logs:

```bash
STAIRCASE_VERBOSE=1 STAIRCASE_STEP=0.04 STAIRCASE_REVERSALS=5 /tmp/stairs_sim
```

Notes
- The simulator uses only the StaircaseAlgorithm (no QUEST/hybrid) and prints per-trial snapshots and final test outcome.
- If you want different deterministic response patterns, edit `Tools/staircase_simulator.swift`.
