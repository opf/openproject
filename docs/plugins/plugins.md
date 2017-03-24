# Plugins

## Install plugins
You can install plugins for the following installation methods:

* [Install plugins - packaged installation](https://www.openproject.org/plugins/install-plugins-packaged/)
* [Install plugins - manual installation](https://www.openproject.org/plugins/install-plugins-manual/)

## Develop plugins

We encourage you to extend OpenProject yourself by writing a plugin. Please, read the [plugin-contributions](https://www.openproject.org/develope-openproject/create-openproject-plugin/) guide for more information.

If you are a plugin author and want your plugins to be listed here, leave us a note in our [forums](https://community.openproject.org/projects/openproject/boards), via [twitter](https://twitter.com/openproject) or any other communication channel. We're looking forward to your contribution.

Please note that the plugin author is responsible to keep his plugin up to date with OpenProject development. In case a plugin causes errors, please contact the plugin author and/or write in our support forums. We will remove plugins from this page if we notice that they are not maintained.

## Supported plugins
Supported plugins are compatible with the current OpenProject version. When a plugin has a dependency to another plugin it is necessary that you list both plugins in the Gemfile.plugins.

### Backlogs
* Description: Features for agile teams
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-backlogs)
* Dependency: PDF Export
* Please refer also to the [agile and scrum overview](https://www.openproject.org/collaboration-software-features/#agile-scrum/) page

```
gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => 'stable/5'
gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => 'stable/5'
```

### Cost
* Description: Features for planning and tracking project costs
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-costs)

```
gem 'openproject-costs', git: 'https://github.com/finnlabs/openproject-costs.git', :branch => 'stable/5'
```

### Dark-Theme
* Description: Allows users to switch to the dark theme instead of the OpenProject theme
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-themes-dark)

```
gem 'openproject-themes-dark', git: 'https://github.com/finnlabs/openproject-themes-dark.git', :branch => 'stable/5'
```

### Documents
* Description: Allows adding documents to projects
* Author: [OpenProject Foundation](http://openprojectpr.staging.wpengine.com/open-source/openproject-foundation/)
* Link: [Source](https://github.com/opf/openproject-documents)

```
gem 'openproject-documents', git: 'https://github.com/opf/openproject-documents.git', :branch => 'stable/5'
```

### Global Roles
* Description: Allows users to create top-level projects
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-global_roles)

```
gem 'openproject-global_roles', git: 'https://github.com/finnlabs/openproject-global_roles.git', :branch => 'stable/5'
```

### Local Avatars
* Description: Allows to upload profile images (avatars)
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-local_avatars)

```
gem 'openproject-local_avatars', git: 'https://github.com/finnlabs/openproject-local_avatars', :branch => 'stable/5'
```

### Meeting
* Description: Features to schedule, prepare, and hold meetings
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-meeting)

```
gem 'openproject-meeting', git: 'https://github.com/finnlabs/openproject-meeting.git', :branch => 'stable/5'
```

### My Project Page
* Description: Enables customization of a project's overview page
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-my_project_page)

```
gem 'openproject-my_project_page', git: 'https://github.com/finnlabs/openproject-my_project_page.git', :branch => 'stable/5'
```

### OmniAuth OpenID-Connect-Providers
* Description: Offers a convenient way to configure different OmniAuth OpenIDConnect providers (preconfigured for Google and Heroku).
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/omniauth-openid_connect-providers)

```
gem 'omniauth-openid_connect-providers', git: 'https://github.com/finnlabs/omniauth-openid_connect-providers.git', :branch => 'dev'
```

### OpenID-Connect
* Description: Adds support for OmniAuth OpenID Connect strategy providers, most importantly Google.
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-openid_connect)

```
gem 'omniauth-openid-connect', git: 'https://github.com/finnlabs/omniauth-openid-connect.git', :branch => 'dev'
```

### PDF Export
* Description: Enables story card export for OpenProject Backlogs
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-pdf_export)
* Dependency: Backlogs

```
gem 'openproject-pdf_export', git: 'https://github.com/finnlabs/openproject-pdf_export.git', :branch => 'stable/5'
gem 'openproject-backlogs', git: 'https://github.com/finnlabs/openproject-backlogs.git', :branch => 'stable/5'
```

### Reporting
* Description: Customized cost reporting features
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-reporting)
* Dependency: Costs, Reporting Engine

```
gem 'reporting_engine', git: 'https://github.com/finnlabs/reporting_engine.git', :branch => 'dev'
gem 'openproject-costs', git: 'https://github.com/finnlabs/openproject-costs.git', :branch => 'stable/5'
gem 'openproject-reporting', git: 'https://github.com/finnlabs/openproject-reporting.git', :branch => 'stable/5'
```

### XLS-Export
* Description: Enables work package exports as Excel document
* Author: [OpenProject GmbH](https://www.openproject.org/about-us/)
* Link: [Source](https://github.com/finnlabs/openproject-xls_export)

```
gem 'openproject-xls_export', git: 'https://github.com/finnlabs/openproject-xls_export.git', :branch => 'stable/5'
```

## Community plugins

There are several plugins developed by dedicated community members. We really appreciate their hard work!

Please keep in mind that it can not always be guaranteed that they are compatible with the current OpenProject version. Authors are responsible for maintaining their plugins and are doing the best they can to keep the plugins up to date.  Please contact the authors directly if you have any questions or feedback, or even want to help them out.

### Auto Project
* Description: Creates a project whenever a user is added
* Author: [Oliver Günther](https://github.com/oliverguenther)
* Link: [Source](https://github.com/oliverguenther/openproject-auto_project)

```
gem "openproject-auto_project", git: "https://github.com/oliverguenther/openproject-auto_project.git", :branch => 'stable'
```

### Ensure Project Hierarchy
* Description: Ensures subproject identifiers are prefixed with their parent project's identifier
* Author: [Oliver Günther](https://github.com/oliverguenther)
* Link: [Source](https://github.com/oliverguenther/openproject-ensure_project_hierarchy)

```
gem "openproject-ensure_project_hierarchy", git: "https://github.com/oliverguenther/openproject-ensure_project_hierarchy.git", :branch => 'stable'
```

## Plugins in development (potentially unstable)

### OpenProject Git Hosting
* Description: Provides extensive features for managing Git repositories within OpenProject
* Author: [Oliver Günther](https://github.com/oliverguenther)
* Link: [Source](https://github.com/oliverguenther/openproject-revisions_git)

```
gem "openproject-git_hosting", git: "https://github.com/oliverguenther/openproject-git_hosting.git", :branch => "dev"
```
