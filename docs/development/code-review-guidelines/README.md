# Code review guidelines

This guide serves as a foundation on how to prepare your work for and perform code reviews for OpenProject.

## Preparing your pull request

### Coding style

We try to adhere to the [Ruby community style guide](https://github.com/bbatsov/ruby-style-guide) as well as the [AirBnB JavaScript style guide](https://github.com/airbnb/javascript) with [some extensions for Angular](../style-guide/frontend/). Rules we want to follow are expressed as either Rubocop definitions or eslint rules. Follow your linter to adhere to them.

Due to the age of our codebase, a lot of our code might not yet adhere to these style guides, but we want all new code to adhere to it. You do not have to improve existing code when making changes, but we encourage it. If you do, please do all improvements in a separate commit from the actual change, so the improvements do not hide your actual code changes in a diff.

Before committing, please run your new code through [Rubocop](https://github.com/bbatsov/rubocop). It detects deviations from a lot of things in the style guide and things that are bad practice in general. You obviously do not have to fix issues with existing code. There is a [list of editor plugins](https://docs.rubocop.org/rubocop/1.31/integration_with_other_tools.html#editor-integration) in the Rubocop docs. You can also use `bin/dirty-rubocop` to test them. Pull requests are being linted automatically through a GitHub action.

The same is true for eslint. Your editor will likely have support for eslint checks, and allows you to correct them before committing.

**Lefthook**

For automatically linting your files on committing them, please have a look at [Lefthook](https://github.com/evilmartians/lefthook). You can install these rules by using `bundle exec lefthook install`.

### Structure of commit messages

- First line: less than 72 characters, this is when GitHub shows ‘…’
- Blank line
- Detailed description of the change, wrapped to 72 characters so the text is readable in git log

See the [Git Book](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project#Commit-Guidelines).

### Pull Request description

- Provide a clear title, optionally linking to a work package
- Add steps necessary to review / reproduce / set up development data for testing
- Reference the change in the OpenProject community, if ticket exists. If no ticket exists, double check if one is really optional.

### Testing

- All GitHub workflow actions must be green on continuous integration
- Appropriate unit and integration tests, e.g. test application logic via rspec tests and its integration with the user interface via feature tests
- Test frontend code with appropriate feature specs.
- Forms: besides testing for success response, also test whether values are actually saved, e.g. read form or look into database
- Bugfixes: must contain a test which detects the bug they fix to prevent regressions
- Translations: Never use a specific translation string in a test. We might want to change them in the future and do not want to fix tests when we do.
- We are aware that there are some flickering specs in our codebase, that might fail randomly. We are actively trying to fix those. If you encounter test failures in code that you have not touched, try re-running the specs.

### Security considerations

Every developer and reviewer should read the Rails Security Guide as well as the OWASP top ten.

[Rails Security Guide](https://guides.rubyonrails.org/security.html)

[OWASP Top 10](https://owasp.org/www-project-top-ten/)

### Changelog

- All changes made to the OpenProject software are managed and documented via work packages in the [OpenProject project](https://community.openproject.org/projects/openproject/).
- The [Roadmap view](https://community.openproject.org/projects/openproject/roadmap) gives a corresponding overview.
- For any nontrivial or pure maintenance changes (Gem bumps etc.), please ensure you have a corresponding ticket you link to in the form of `OP##<Work package ID>` or `https://community.openproject.org/work_packages/ID` in your pull request.
- To prevent inconsistencies and avoid redundant work there is no additional change log in the source code. Releases will contain a changelog of the publicly visible tickets in the GitHub releases pages, as well as [on our release notes](../../release-notes/).

### Marking your code as reviewable

Before requesting a review, double check your own changes:

- Are they complete? Did you add that spec Did you take a look at the diff yourself?
- Did you forget to remove any temporary code, debugging steps, or similar?

Once your pull request is ready to be reviewed, convert it from a draft and add the label `needs review`. You can bookmark this query to always show all pull requests recently marked as reviewable: https://github.com/opf/openproject/pulls?q=is%3Aopen+is%3Apr+label%3A%22needs+review%22

Do not explicitly request people or groups as reviewers unless you have collaborated with them already, or have a good reason to request specific feedback.

Wait for a reviewer to start. If you get feedback or requested changes, do not take them personally. Code is highly personal, and everyone might have different thoughts or ideas.

Try to respond to every feedback and resolve feedback that you addressed already. Re-request a review from the same person if you addressed all remarks.

## Reviewing

You've found a pull request you want to review. Here is how to do it:

### Timeliness

Reviewing code from your colleagues has higher priority than picking up more work. When you start your day, or in between working on other topics, please check the above link if there is any review requested.

If a review is left untouched, feel free to request a review from a group or link the pull request in question in the developers element channel.

### Taking a review

If you're ready to perform a review for a pull request, do these things:

- Remove the `needs review` label. This is a semaphore and ensures only one developer performs a review
- If there is a linked ticket that has an appropriate status workflow, set it to `in review` and assign yourself
- Optionally, request yourself as a reviewer

### Correctness

As a reviewer, your job is not to make sure that the code is what you would have written – *because it will not be*. Your job as a reviewer of a piece of code is to make sure that the code as written by its author is correct.

Try to think of edge cases when testing or evaluating the code, double check the test coverage. But do not frown if you merged the pull request and something broke after all. This is the learning path to avoiding this mistake on the next attempt. Not doing a review in the first place will not move you forward either.

### Language

Keep in mind that we're all trying to do the correct thing. Be kind and honest to one another, especially since our reviews are public for everyone to see.

- Prefer questions instead of demands
- When in doubt, ask for a meeting to clarify things before assuming someone made a mistake.

### Testing

Verify that the appropriate tests have been added as documented above.

When testing a feature or change, check out the code test at least the happy paths according to the specification of the ticket.

### Documenting changes right away

If possible, add smaller documentation changes right away.

If there are breaking changes (e.g., to permissions, code relevant for developers), add them to the release notes draft for the release or create a new draft if none exists yet.

## Other

- For external contributions: Check whether the author has signed a [Contributor License Agreement](../#openproject-contributor-license-agreement-cla) and kindly ask for it if not.

- Copyright notice: When new files are added, make sure they contain the OpenProject copyright notice (copy from any file in OpenProject).

- Adding Gems: When adding gems, make sure not only the Gemfile is updated, but also the Gemfile.lock.

## Readability

The reviewer should understand the code without explanations outside the code.

*There is never anything wrong with just saying “Yup, looks good”. If you constantly go hunting to try to find something to criticize, then all that you accomplish is to wreck your own credibility.*

*You should not rush through a code review – but also, you need to do it promptly. Your coworkers are waiting for you.*

## Completing the review

Once you've completed the review, you might have left feedback for the developer. In that case:

- Publish the review
- If any, assign the linked work package back to the developer and set to `in development`

If there are no change requests, perform these steps:

- approve the pull request
- merge it using the `Merge pull request` button.
- If there is a linked ticket, set it to merged (or closed for an Implementation ticket) and unassign yourself or the developer.

**Why merge, not squashing?**

We do not use squashing to retain any commit information of the original developer, which might contain valuable information. If there are a lot of bogus commits, we squash them on the PR first and then merge them. Having all information about a change is deemed more important than a strictly linear history.

The only exception to this rule are single commit pull requests, which can be applied to dev using `Rebase and merge` instead.

## Citations

[Things everyone should do: code review](https://blog.csdn.net/zhangmike/article/details/30198411)

[Why code reviews are good for you](https://beust.com/weblog/2006/06/22/why-code-reviews-are-good-for-you/)

[Code review FAQ](https://www-archive.mozilla.org/hacking/code-review-faq)
