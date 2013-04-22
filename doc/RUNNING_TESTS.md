# Testing OpenProject

## Cucumber

The cucucmber features can be run using rake. You can run the following
rake tasks using the command `bundle exec rake <task>`.

* `cucumber` Run core features
* `cucumber:plugins` Run plugin features
* `cucumber:all` Run core and plugin features
* `cucumber:custom[features]`: Run single features or folders of features

    Example: `cucumber:custom[features/issues/issue.feature]`
    * When providing moultiple features, the task name and arguments must
      be enclosed in quotation marks.

      Example: `bundle exec rake "cucumber:custom[features/issues features/projects]"`

`cucumber:plugins` and `cucumber:all` accept an optional parameter which
allows specifying custom options to cucumber. This can be used for
executing scenarios by name, e.g. `"cucumber:all[-n 'Adding an issue link']"`.
Like with spaces in `cucumber:custom` arguments, task name and arguments
have to be enclosed in quotation marks.

Here are two bash functions which allow using shorter commands for running
cucumber features:

    # Run OpenProject cucumber features (like arguments to the cucumber command)
    # Example: cuke features/issues/issue.feature
    cuke() { bundle exec rake "cucumber:custom[$*]"; }

    # Run OpenProject cucumber scenarios by name
    # Example: cuken Adding an issue link
    cuken() { bundle exec rake "cucumber:all[-n '$*']"; }


## Spec

TBD
