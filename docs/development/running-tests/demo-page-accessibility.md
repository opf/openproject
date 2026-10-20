# Demo page accessibility audit

The demo sweep is opt-in while its known-violation registry is incomplete. Normal RSpec runs exclude `:axe_sweep`, including when the feature spec path is supplied. Run it explicitly with Selenium and the normal feature-test prerequisites:

```sh
bundle exec rspec spec/features/a11y/demo_pages_spec.rb --tag axe_sweep
```

For a Codex OrbStack checkout:

```sh
rtk proxy python3 ~/git-repos/agent-plans/tools/openproject-codex/environment.py test spec/features/a11y/demo_pages_spec.rb --tag axe_sweep
```

The example seeds standard RootSeeder demo data in the test database, logs in as the seeded admin, and discovers global, administration and demo-project menu links. It scans whole pages, follows at most one matching show/edit detail link immediately after each index, and stops at depth two. Only same-origin recognized GET index/show/edit destinations qualify; action links, method overrides, downloads, exports and fragments are excluded. Query strings and fragments are removed when deduplicating pages. Safe canonical redirects are validated against the same link policy, recorded as requested-to-final aliases, and scanned once under the final page path. This bounds coverage to default page states; filtered views and interactive dialog states are separate audits.

The default cap is 100 pages. Set `AXE_SWEEP_MAX_PAGES` in the test process environment to change it. Both reports record the cap, depth, eligible menu/detail discoveries, pages whose links were not expanded at depth two, and omitted queued pages when capped. The untruncated feature guard also requires menu discovery at every seed root and at least one scanned demo detail. A truncated run describes bounded coverage rather than exhaustive coverage.

Reports are written to `tmp/axe-audit/report.json` and `report.md`, including partial results after a page error. Each run replaces those files; archive them separately when comparing runs. Findings group by rule and page, with numeric record IDs collapsed in selector keys and original selectors preserved for every page occurrence.

`A11y::DemoSweep::KNOWN_VIOLATIONS` is deliberately empty and separate from the Lookbook registry. Add an exemption only after reviewing the finding, with a page-path regular expression, exact axe rule ID and nonempty tracking reason. Unknown findings or navigation/scan errors fail even if other findings are registered. Registered-only findings mark the run pending; a clean run passes. Never copy the initial report into blanket exemptions.

Before enabling the guard in default CI, complete and review the registry, inspect the coverage and truncation metadata, and remove the `axe_sweep` exclusion in `spec/rspec_helper.rb` in a separate change.

The fast crawler and report specs run without Rails:

```sh
bundle exec rspec spec/lib/a11y/demo_sweep_spec.rb
```
