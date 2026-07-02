> [!WARNING]
> Flaky specs

${SPECS}

<details>
<summary>🤖 Ask Copilot to investigate</summary>

Copy the prompt below into a new comment on this PR to delegate the investigation to GitHub Copilot. It will look into the flakiness and open a separate pull request with you as reviewer.

```
@copilot The following spec(s) are flaky in CI (first seen on PR #${PR_NUMBER}, linked for reference only):

${SPECS}

Treat this as a standalone task, unrelated to PR #${PR_NUMBER}. Create a new branch from origin/dev and open a new pull request targeting dev — do not stack it on PR #${PR_NUMBER} or reuse that branch.

Follow the playbook in docs/development/testing/handling-flaky-tests/README.md to find the root cause and fix the underlying race — do not skip, delete, or weaken the spec to make it pass; disabling is a last resort per the playbook, and only with a bug ticket. Verify the fix by running the spec(s) repeatedly (e.g. `script/bulk_run_rspec --run-count 10`).

If you cannot reproduce the flake or are not confident in a fix after reasonable investigation, do not fabricate a change or skip the spec to force CI green. Instead, leave the pull request in draft and document what you tried, the suspected cause, and any leads in its description, then assign @${PR_AUTHOR} to take over.

Once the fix is verified, title the PR after the spec(s) it fixes, and use the PR description to explain the root cause, how the change resolves it, and the before/after results. Label the PR `flaky-spec`, assign @${PR_AUTHOR}, and request a review from @${PR_AUTHOR}.
On every commit, set @${PR_AUTHOR} as the sole co-author with a `Co-authored-by:` trailer (use their GitHub no-reply email so it links to their account), so it is traceable who dispatched the fix.
```

</details>
