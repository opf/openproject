## Contributing

[fork]: https://github.com/twitter/secureheaders/fork
[pr]: https://github.com/twitter/secureheaders/compare
[style]: https://github.com/styleguide/ruby
[code-of-conduct]: CODE_OF_CONDUCT.md

Hi there! We're thrilled that you'd like to contribute to this project. Your help is essential for keeping it great.

Please note that this project is released with a [Contributor Code of Conduct][code-of-conduct]. By participating in this project you agree to abide by its terms.

## Submitting a pull request

0. [Fork][fork] and clone the repository
0. Configure and install the dependencies: `bundle install`
0. Make sure the tests pass on your machine: `bundle exec rspec spec`
0. Create a new branch: `git checkout -b my-branch-name`
0. Make your change, add tests, and make sure the tests still pass and that no warnings are raised
0. Push to your fork and [submit a pull request][pr]
0. Pat your self on the back and wait for your pull request to be reviewed and merged.

Here are a few things you can do that will increase the likelihood of your pull request being accepted:

- Write tests.
- Keep your change as focused as possible. If there are multiple changes you would like to make that are not dependent upon each other, consider submitting them as separate pull requests.
- Write a [good commit message](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html).

## Releasing

0. Ensure CI is green
0. Pull the latest code
0. Increment the version
0. Run `gem build secure_headers.gemspec`
0. Bump the Gemfile and Gemfile.lock versions for an app which relies on this gem
0. Test behavior locally, branch deploy, whatever needs to happen
0. Run `bundle exec rake release`

## Resources

- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [Using Pull Requests](https://help.github.com/articles/about-pull-requests/)
