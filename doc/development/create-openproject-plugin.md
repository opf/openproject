# Create an OpenProject plugin

OpenProject plugins are special ruby gems. You may include them in your `Gemfile.plugins` file like you would do for any other gem. Fortunately, this gives us plugin version management and dependency resolution for free.

## Generate the plugin

You can generate a new plugin directly from OpenProject. Think of a good name and a place (in your filesystem) where the plugin should go. In this example, we have a `plugins` directory right next to the `openproject` directory. Then do

```bash
bundle exec rails generate open_project:plugin my_plugin ../plugins/
```

This generates the plugins `openproject-my_plugin` into the directory `../plugins/openproject-my_plugin`. The new plugin is a rails engine, which can be published as a gem.

You may want to update the generated plugin's gemspec (`openproject-my_plugin.gemspec`).

**Example Plugin**

There is an [example plugin](https://github.com/opf/openproject-proto_plugin) which does some of the basic things (adding menu items, hooking into views, defining a project menu, etc.) and provides further info in its README.

Instead of generating a new plugin you can also just clone the example plugin and adapt it.

## Hook the new plugin into OpenProject

To include the new plugin into OpenProject, we have to add it into `Gemfile.plugins` like any other OpenProject plugin. Add the following lines to `Gemfile.plugins`:

```
group :opf_plugins do
  gem "openproject-my_plugin", :path => '../plugins/openproject-my_plugin'
end
```

If there already is an `opf_plugins` group, just add the `gem` line to it.

Once you've done that install it via

```bash
bundle install
```

## Start coding

You may have a look at some existing OpenProject plugins to get inspiration. It is possible to add new routes, views, models, … and/or overwrite existing ones.

Feel free to ask for help in our [Development Forum](https://community.openproject.org/projects/openproject/boards/7).

## Steps to release a plugin

The following steps are necessary to release a new plugin:

### Code Review
A code review should check the whole code and remove glitches like:

- Unappropiate comments
- Deactivated code
- Minor cases of code smell

### Resolve licensing and copyright issues

1. Check the license and the copyright of the plugin to be released

 Usually, this should be GPLv3 and we are the copyright owner. However, some plugins might have additional authors or might originate from code with a different license. These issues have to be resolved first. Also check the years in the copyright. If you need to find all contributors of a repository including their contribution period use the following rake task:
 ```bash
rake copyright:authors:show['../Path/to/repository/']
```

2. Add a copyright notice to all the source files

 There is a rake task in the core to perform this job. Use `rake copyright:update['path_to_plugin']` (e.g. `rake copyright:update['../plugins/openproject-global_roles']`) to add the copyright header in `doc/COPYRIGHT_short.md` to all relevant plugin files.
 If no such file exists, `doc/COPYRIGHT_short.md` from the core is used.

3. Check for existence of `doc/COPYRIGHT.md` and `doc/GPL.txt` if referenced by the copyright notice.

### Complete the readme file or add one if not existing

There should be a file README.md containing:

1. A description about what the plugin is actually doing
2. Requirements to use the plugin
3. Instructions how to install and uninstall a plugin
4. Notes where to report bugs
5. Notes where to contribute
6. Credits

If you’re unsure about if/who to give credit, you should take a look into the changelog:

```bash
git log --pretty=format:%aN | sort | uniq -c | sort -rn
```

For your convenience you may use the following rake task, that extracts all authors from a repository

```bash
rake copyright:authors:show['../Path/to/repository/']
```

7. Licensing information.
It is probably best to use READMEs of already released plugins as a template.

### Complete the gemspec

1. Add the license to the gemspec of the plugin if not already there.
2. Add any files that should be included to the gemspec (e.g. the `doc` folder, the `db` folder if there are any migrations, the `CHANGELOG.md`, and the `README.md`).
3. Check authors and email point to the right authors.
4. The homepage should be the homepage of the plugin.
5. Check if summary and description are there.
6. Check if all dependencies are listed (this might be difficult, I know): There should be a sentence in the README, that this is an OpenProject-Plugin and requires the core to run. Apart from that, state only dependencies that are not already present in core.
7. While you are at it, also check if there is any wiring to core versions necessary in engine.rb; also check, that the url of the plugin is wired correctly.
8. Push the version of the plugin, mostly by just removing any .preX specials at the end.
9. Don’t forget to add a changelog entry.
10. Commit everything.
11. Also create a release tag (named ‘release/<version>’ for example ‘release/1.0.2′) to name the new version.
12. Push the tag with `git push --tags`.

### Publish the gem at Rubygems

- `gem update --system`
- Ensure gemspec fields are complete and version number is correct
- `gem build <name>.gemspec`
- `gem push <name>-<version>.gem`. This asks for your user/password
- Go to https://rubygems.org, log in, go to the dashboard, click on the uploaded gem, click edit.  Set URLs, at least source code URL and Bug Tracker URL
- You are done .
- *Be careful when publishing a gem.Once it is published, it cannot be replaced in the same version*. It is only possible to take a version out of the index and publish a new version.

### Create public visibility

1. Make the github repository public.
2. Make the plugin project public.
  Do a little cleanup work first by removing modules not needed. Currently,
  Activity, Issue Tracking, Time Tracking, Forums, and Backlogs are default.
  Also, the My Project Page should only show Project Description and Tickets blocks.
3. Create a news article about the newly released plugin and its features.
4. Twitter with a link to the news article.
5. If the plugin is referenced in our feature tour, add a download link to the plugin in the feature tour
6. Add the newly released plugin to the list of [released plugins](https://www.openproject.org/download/install-plugins/openproject-plugins/).


# Frontend plugins [WIP]

Plugins that extend the frontend application may be packaged as **npm modules**.
These plugins must contain a `package.json` in the root directory of the plugin.

Plugins are responsible for loading their own assets, including additional
images, styles and I18n translations.

Translations are processed by I18n.js through Rails and will be picked up from `config/locales/js-<locale>.js`.

Pure frontend plugins are currently not possible without modifications to the OpenProject core `package.json`.
We instead recommend to create a hybrid gem plugin instead (see below).

## Hybrid plugins

Plugins that extend both the Rails and frontend applications are possible. They
must contain both a `Gem::Specification` and `package.json`.

_CAVEAT: npm dependencies for hybrid plugins are not yet resolved._

**To use a hybrid plugin:**

  * declare the dependency in `Gemfile.plugins` within the `:opf_plugins` group
    using the Bundler DSL.

  * then run `bundle install`.

Provided Ruby Bundler is aware of these plugins, Webpack (our node-based build pipeline)
will bundle their assets.
