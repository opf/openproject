OpenProject Documents Plugin
===========================

This plugin adds features to connect and categorize documents with your project.

Under `Modules >> Administration >> Enumerations` you can find the section `Document categories`
where you can define several document categories that projects can use to categorize their documents.

Documents can be enabled for every project individually. Simply activate the `Documents` module in the project settings.

When you go to any of your projects you can see the entry `Documents` in the main menu. There you can
attach new documents to the project by following the `New document` link located in the top right corner of the page.

The form allows you to select one of the categories you defined earlier, choose a title and define a description.
You can attach files from your local hard disk to the document entry which will make them available to anybody
who has access to the document.

Requirements
------------

The OpenProject Documents plug-in requires the [OpenProject Core](https://github.com/opf/openproject/) in version greater or equal to *3.0.0*.


Installation
------------

For OpenProject Documents you need to add the following line to the `Gemfile.plugins` of OpenProject (if you use a different OpenProject version than OpenProject 5, adapt `:branch => "stable/5"` to your OpenProject version):

`gem "openproject-documents", git: "https://github.com/opf/openproject-documents.git", :branch => "stable/5"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`


Tests
-----

Assuming you have to following directory structure:

```
.
├── openproject
├── openproject-documents
```

Replace the openproject-document ``Gemfile.plugins`` entry with the following:

```
gem "openproject-documents", path: "../openproject-documents"
```

You run the specs with the following commands:

```
cd openproject
rake db:test:load # this needs to be done only once
rspec ../openproject-documents
```

Deinstallation
--------------

Remove the line

`gem "openproject-documents", git: "https://github.com/opf/openproject-documents.git", :branch => "stable/5"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this leaves plugin data in the database. Currently, we do not support full uninstall of the plugin.


Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/documents


Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/opf/openproject-documents`

Licence
-------

Copyright (C) 2009-2015 the OpenProject Foundation (OPF)
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
