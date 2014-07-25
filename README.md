OpenProject PDF Export Plugin
===========================

This Plugin adds features which enable the configuration and generation of printable export card PDFs,
especially useful to export story cards from the plugin "OpenProject Backlogs":https://www.openproject.org/projects/plugin-backlogs


Requirements
------------

The OpenProject PDF Export plugin requires the [OpenProject Core](https://github.com/opf/openproject/) in
version greater or equal to *3.0.0*.

Tests for this plugin require `pdf-inspector`, so just add the following line to
OpenProject's `Gemfile.plugin`:

`gem "pdf-inspector", "~>1.0.0", :group => :test`


Installation
------------

For OpenProject PDF Export itself you need to add the following line to the
`Gemfile.plugins` of the project which is using the plugin:

`gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`

There is a seed file to load a default ExportCardConfiguration model, although this is not strictly required.


Deinstallation
--------------

Remove the line

`gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this leaves plugin data in the database. Currently, we do not
support full uninstall of the plugin.

Usage
------------

The plugin provides an admin interface for ExportCardConfiguration CRUD. Existing ExportCardConfigurations can then be used to export data in PDF form, the configuration defining the layout of the card and the specific data which appears in it. The DocumentGenerator init takes a ExportCardConfiguration and an array of any object. It is left to the developer to make sure the fields in the config match the given data. A ExportCardConfiguration currently allows for the following fields to be defined:

Name - A unique identifier for the configuration.
Per Page - The number of export cards which will appear on each page of the exported PDF.
Page Size - Currently we only support A4 paper size.
Orientation - Portrait of Landscape.
Rows - A YAML text block which defines in detail what should appear in each row and column of the export cards.

The following sample YAML shows the required form and all of the available configuration options:

<pre>
group1:
  has_border: false
  height: 200
  rows:
    row1:
      height: 50
      priority: 1
      columns:
        id:
          has_label: false
          min_font_size: 10
          max_font_size: 20
          font_size: 20
          font_style: bold
          text_align: left
          minimum_lines: 2
          render_if_empty: false
          width: 30%
        due_date:
          has_label: false
          font_size: 15
          font_style: italic
          minimum_lines: 2
          render_if_empty: false
          width: 70%
    row2:
      priority: 2
      columns:
        status:
          has_label: true
          indented: true
          font_size: 15
          font_style: normal
          minimum_lines: 1
          render_if_empty: true
group2:
  has_border: true
  rows:
    row1:
      height: 80
      priority: 2
      columns:
        description:
          has_label: true
          indented: false
          font_size: 15
          font_style: normal
          minimum_lines: 1
          render_if_empty: true
    row2:
      priority: 2
      columns:
        status:
          has_label: true
          font_size: 15
          font_style: normal
          minimum_lines: 1
          render_if_empty: true
    row2:
      priority: 2
      columns:
        custom_field_name:
          has_label: true
          font_size: 15
          minimum_lines: 1
group3:
  rows:
    row1:
      priority: 2
      columns:
        children:
          has_label: true
          has_count: true
          indented: true
          font_size: 15
          font_style: normal
          minimum_lines: 1
          render_if_empty: true

</pre>
The config is divided into groups. A group can have a height property which will enforce the minimum height of the group in pixels. The has_border property can be set to true which will draw a border around the rows in the group.

Any number of rows can be defined. The font_size and minimum_lines properties define how much height on the card is given to the row. The plugin will attempt to assign enough space to each of the rows, however space will be assigned based on the priorities of the the rows, with rows with lower priority (higher numbers) being reduced and removed first if there is not enough for all the data. The row height can be forced by giving a value, in pixels, for the row height property. This will override the assigned row height.

The name of the column informs the plugin which data should be read from the model (status, due_date, id, etc.). There can be any number of columns per row. Custom field names can also be used. Columns are given an equal share of the row width unless a specific width % is given. If there is more text in the column than can fit into its assinged space on the card then the text will be truncated.

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/pdf-export


Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/openproject-pdf_export`


Credits
-------

We would like to thank

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorhip

Licence
-------

Copyright (C)2014 the OpenProject Foundation (OPF)<br />

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
