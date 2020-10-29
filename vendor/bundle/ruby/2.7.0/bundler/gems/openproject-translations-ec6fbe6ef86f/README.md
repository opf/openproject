# OpenProject Translations Plugin

`openproject-translations` is an OpenProject plugin, which adds more languages to your OpenProject installation.

This plugin uses crowdin for translations.
All translations are fetched from [our crowding project](https://crowdin.net/project/openproject) on a daily basis. If you want to change translations, you are very welcome to do so via crowdin.

Please keep in mind that the OPF team does not speak all the languages this plugin provides, thus we cannot guarantee the correctness of translations.

We plan to release this plugin every time an OpenProject core release is done.

**Beware**:

* when translating `general_lang_name` do not translate the word 'English', but fill in the name of the language you are currently translating

## Technical Details

We can split this up in three parts: storing locales, loading locales,
updating locales.

### Storing locales

* Core: The locales (except for english) are stored in
  OpenProject-Translations
* Plugins: All locales are stored in the plugins themselves.

### Loading Locales

* Rails locales are loaded automatically. OpenProject-Translations just
  patches the location Rails looks for locales.
* Js locales get required by webpack during the rake task
  `assets:webpack`. Currently, js locales from the core are required by
OpenProject-Translations and js locales from plugins are required by
each plugin individually.

### Updating Locales

* This plugin provides several rake tasks to update locales. These tasks keep the following up to date: the source files in Crowdin and the translated files in the GitHub repos. We execute these tasks once a day.

## Requirements

* OpenProject version **3.0.0 or higher** ( or a current installation from the `dev` branch)

## Plugin Installation

Starting with OpenProject 4.2.0 this plugin belongs to the Gemfile of the core. Thus, you do not need to install it anymore.

## Contact

OpenProject is supported by its community members, both companies and individuals.

Please find ways to contact us on the OpenProject [support page](https://www.openproject.org/support).

## Contributing

This OpenProject plugin is an open source project and we encourage you to help us out. We'd be happy if you do one of these things:

* Add new translations at [our crowin project](https://crowdin.net/project/openproject)
* Create a new [work package in the Translations plugin project on openproject.org](https://www.openproject.org/projects/translations/work_packages) if you find a bug or need a feature
* Help out other people on our [forums](https://www.openproject.org/projects/openproject/boards)
* Contribute code via GitHub Pull Requests, see our [contribution page](https://www.openproject.org/projects/openproject/wiki/Contribution) for more information

## Community

OpenProject is driven by an active group of open source enthusiasts: software engineers, project managers, creatives, and consultants. OpenProject is supported by companies as well as individuals. We share the vision to build great open source project collaboration software.
The [OpenProject Foundation (OPF)](https://www.openproject.org/projects/openproject/wiki/OpenProject_Foundation) will give official guidance to the project and the community and oversees contributions and decisions.

## Repository

This repository contains two main branches:

* `dev`: The main development branch. We try to keep it stable in the sense of all tests are passing, but we don't recommend it for production systems. Translations in this branch should match those required by the `dev` branch of the OpenProject core.
* `stable`: Contains the latest stable release that we recommend for production use. Use this if you always want the latest version of this plugin together with the `stable` branch of the OpenProject core.

## License

Copyright (C) 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See [doc/COPYRIGHT.md](doc/COPYRIGHT.md) for details.
