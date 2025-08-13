### Devcontainer benchmark results

Sources analyzed:
- benchmarking/scenario_c/20250810_234448_scenario_c.log
- benchmarking/scenario_b/20250811_205949_scenario_b.log
- benchmarking/scenario_a/20250812_084413_scenario_a.log

Summary (total elapsed):
- Scenario A (Baseline, no cache): 1636s (~27m16s)
- Scenario B (Optimized, Docker Hub): ~4586s (~76m26s)
- Scenario C (Optimized, local cache): 2294s (~38m14s)

Details (key long-running steps observed in Scenario B):
- rsync third_party submodules: 6m33.7s
- pip install prebuilt xformers wheel: 1.3s
- editable install (-e) of xformers: 25m34.4s

Conclusion:
- Scenario A is now the default and only supported path. It was fastest (~27m) and compiles once without redundant steps.
- Scenarios B and C are removed from active use. Their artifacts remain available in git history for reference, but we will not maintain them going forward.

Interpretation:
- The “optimized” paths add overhead that negates caching benefits in practice. A single editable build (Scenario A) is simpler and faster end-to-end.

Next steps:
- Update documentation and tooling to assume Scenario A by default.
- Retain the single-log runner and per-step timers to validate future changes and track performance.


