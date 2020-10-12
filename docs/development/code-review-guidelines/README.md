# Code review guidelines

## Correctness

*As a reviewer, your job is not to make sure that the code is what you would have written – because it will not be. Your job as a reviewer of a piece of code is to make sure that the code as written by its author is correct.*

## Coding style

We try to adhere to the [Ruby community styleguide](https://github.com/bbatsov/ruby-style-guide). At some point we will have to make decisions about some rules that are not clear or defined within that styleguide. In that case, we should either fork it or note all decisions here.

Most of our code does not yet adhere to this styleguide, but we want all new code to adhere to it. You do not have to improve existing code when making changes, but we encourage it. If you do, please do all improvements in a separate commit from the actual change, so the improvements do not hide your actual code changes in a diff.

Before committing, please run your new code through [Rubocop](https://github.com/bbatsov/rubocop). It detects deviations from a lot of things in the style guide and things that are bad practice in general. You obviously do not have to fix issues with existing code. There is a [list of editor plugins](https://github.com/bbatsov/rubocop#editor-integration) in the Rubocop readme.

When reviewing code and you think the author has not run the code through Rubocop, please ask them to.

## Commit messages

- First line: less than 72 characters, this is when GitHub shows ‘…’
- Blank line
- Detailed description of the change, wrapped to 72 characters so the text is readable in git log

See the [Git Book](http://git-scm.com/book/en/Distributed-Git-Contributing-to-a-Project#Commit-Guidelines).

## Testing

- All tests must be green on continuous integration
- Appropriate unit and integration tests, e.g. test application logic via rspec tests and its integration with the user interface via Cucumber tests
- Test JavaScript code, e.g. via Jasmine or Selenium/Cucumber, but: Cucumber tests that do not test JavaScript must not have the @javascript tag, otherwise they run slower
- Look for sufficient coverage of both Ruby and JavaScript code. CI will provide at least Ruby line coverage information at some point in the future
- Forms: besides testing for success response, also test whether values are actually saved, e.g. read form or look into database
- Bugfixes: must contain a test which detects the bug they fix to prevent regressions
- Translations: Never use a specific translation string in a test. We might want to change them in the future and do not want to fix tests when we do.

## Security

Every developer and reviewer should read the Rails Security Guide.

[Rails Security Guide](http://guides.rubyonrails.org/security.html)

## Changelog

- All changes made to the OpenProject software are managed and documented via work packages in the [OpenProject project](https://community.openproject.org/projects/openproject/).
- The [Roadmap view](https://community.openproject.com/projects/openproject/roadmap) gives a corresponding overview.
- To prevent inconsistencies and avoid redundant work there is no additional change log in the source code.

## Other

- For external contributions: Check whether the author has signed a [Contributor License Agreement](../#openproject-contributor-license-agreement-cla) and kindly ask for it if not.
- Copyright notice: When new files are added, make sure they contain the OpenProject copyright notice (copy from any file in OpenProject).
- Adding Gems: When adding gems, make sure not only the Gemfile is updated, but also the Gemfile.lock.
- No trailing whitespace.
- [Single newline at the end of a file](http://stackoverflow.com/questions/729692/why-should-files-end-with-a-newline).

## Readability

The reviewer should understand the code without explanations outside the code.

*There is never anything wrong with just saying “Yup, looks good”. If you constantly go hunting to try to find something to criticize, then all that you accomplish is to wreck your own credibility.*

*You should not rush through a code review – but also, you need to do it promptly. Your coworkers are waiting for you.*

## Citations

http://scientopia.org/blogs/goodmath/2011/07/06/things-everyone-should-do-code-review/

http://beust.com/weblog/2006/06/22/why-code-reviews-are-good-for-you/

https://developer.mozilla.org/en/Code_Review_FAQ
