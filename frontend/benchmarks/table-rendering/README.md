# Production table benchmark

Run from `frontend` with the Node version in `package.json` (currently 24.22.1) and installed dependencies/Playwright Chromium. This target uses actual AOT production components and script optimization; it is separate from the unit-test builder. The runner checks production mode and records bundle hashes, Node/browser versions, raw samples and medians.

## Build once, run suites

```sh
rtk proxy npx ng run OpenProject:table-benchmark
rtk proxy env TABLE_BENCHMARK_OUTPUT=dist/table-default.json node benchmarks/table-rendering/run.mjs
rtk proxy env TABLE_BENCHMARK_SUITE=wide TABLE_BENCHMARK_OUTPUT=dist/table-wide.json node benchmarks/table-rendering/run.mjs
rtk proxy env TABLE_BENCHMARK_SUITE=actions TABLE_BENCHMARK_OUTPUT=dist/table-actions.json node benchmarks/table-rendering/run.mjs
```

The default suite measures 100/500 rows with ID/subject, plus 500 rows and 20 expanded shared-target relations. Wide measures 100/500 rows with eight simple or ten mixed columns, including real HAL highlighting and Link fields. Actions measures 500 ID/subject rows with the production details/context actions and registered Primer tooltips. Every suite exercises both renderers, two warmups and seven measured samples, with DOM/refresh/identity assertions. Actions additionally checks URLs, labels and tooltip ownership after each operation. Distinct output paths prevent overwriting results. `npm run benchmark:table:production` combines a build and default run.

## Compare saved builds

Copy the complete output before changing source:

```sh
rtk proxy cp -R dist/table-rendering-benchmark dist/table-baseline
rtk proxy npx ng run OpenProject:table-benchmark
rtk proxy env TABLE_BENCHMARK_BUILD_DIRECTORY=dist/table-baseline TABLE_BENCHMARK_SUITE=wide TABLE_BENCHMARK_OUTPUT=dist/before-wide.json node benchmarks/table-rendering/run.mjs
rtk proxy env TABLE_BENCHMARK_SUITE=wide TABLE_BENCHMARK_OUTPUT=dist/after-wide.json node benchmarks/table-rendering/run.mjs
```

Use identical fixture/harness versions, Node and browser versions. Alternate repeated baseline/candidate runs and inspect legacy drift as well as Angular results. The build-directory override must point to the directory containing `index.html` (an output-path override may introduce a `browser` subdirectory). Preserve every JS chunk, not just `main`. Older bundles without the requested suite/capabilities are rejected.

## Diagnostic profiles

```sh
rtk proxy npx ng run OpenProject:table-benchmark --source-map
rtk proxy env TABLE_BENCHMARK_SUITE=wide TABLE_BENCHMARK_CASE=mixed10:500:0:Angular TABLE_BENCHMARK_INITIAL_ONLY=1 TABLE_BENCHMARK_PROFILE_INTERVAL_US=100 TABLE_BENCHMARK_PROFILE=dist/initial.cpuprofile TABLE_BENCHMARK_OUTPUT=dist/initial-profile.json node benchmarks/table-rendering/run.mjs
rtk proxy node benchmarks/table-rendering/profile-summary.mjs dist/initial.cpuprofile dist/table-rendering-benchmark/main-HASH.js.map dist/initial-summary.json
```

Use the exact matching map from that build. Scenario keys are `[simple8:|mixed10:]rows:relationParents:Angular|legacy`; actions uses `500:0:Angular` or `500:0:legacy` with the actions suite selected. Initial-only omits redraw/refresh. Profiles perturb execution: use them for attribution, never as unprofiled timing comparisons.

## Timing boundaries and limits

`initialMs` and `redrawMs` end at table-render publication; `refreshMs` measures the synchronous refresh call. Stage samples separate row building and synchronous Angular `renderRows`. These boundaries do not guarantee all deferred action/tooltip effects have completed.

Actions also reports `actionsReady` medians/raw samples from the same operation start through `fixture.whenStable()`, before correctness assertions. This includes a small amount of stage bookkeeping after commit. It is **not paint timing** and does not prove layout, tooltip animation or browser paint completion. Assertions/readiness waits occur outside the original commit metrics. No menu-opening interaction is measured.

This is a synthetic readonly fixture with stubbed translations/services, no full application styles/network, and a headless browser. It does not establish full-app performance or interactive editing latency. The runner does **not automatically reject CPU contention**. Audit unrelated workloads separately; identify the benchmark's own browser descendants by PID ancestry so their CPU is not mislabeled as external. Retain and label contaminated runs; do not stop user applications to force quiet. No CI workflow or absolute timing gate is included.
