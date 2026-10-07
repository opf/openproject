---
sidebar_navigation:
  title: Global settings
description: How global settings are defined, shown in the administration and found in the settings search
keywords: settings, administration, Settings::Definition, Settings::Pages
---

# Global settings

Global settings are defined once and then rendered, updated and made searchable from that definition. A new setting
usually needs no template, form or controller.

## Defining a setting

Every global setting has an entry in `config/constants/settings/definition.rb`, or is added by a module with
`Settings::Definition.add` in an engine initializer. The definition holds the default value, the format and the allowed
values, which also determine how the setting is rendered:

| Format and allowed values | Input |
|---|---|
| boolean | check box |
| integer, float | number field, limited to an allowed range |
| string, symbol | text field, or radio buttons (up to five allowed values) or a select list |
| array with allowed values | check box group |
| array without allowed values | text area with one value per line |

The label is the `setting_<name>` translation, the caption the `setting_<name>_caption` (or `_caption_html`) one.
Anything else is given as `ui` hints:

```ruby
attachment_max_size: {
  default: 5120,
  ui: { unit: :"number.human.storage_units.units.kb" }
}
```

The hints are documented in `config/constants/settings/pages.rb`. The most common ones are `input`, `label`,
`caption`, `warning`, `unit`, `values` (for selects and groups) and `parse` (to transform the submitted value). Labels,
captions and other hints can be lambdas, which are evaluated in the view context.

## Showing a setting in the administration

Settings are placed on administration pages in `config/initializers/settings_pages.rb`, or by modules in an engine
initializer:

```ruby
Settings::Pages.draw do
  page :exports, menu_item: :settings_exports do
    setting :work_packages_projects_export_limit, input_width: :xsmall
    setting :csv_escape_formulas
  end
end
```

Each page belongs to an entry of the admin menu, which provides its title and breadcrumbs. Hints given on the page
override those of the definition. Further options let pages

* group settings into `section`s with a heading and description,
* show settings only while another one is checked or has a given value (`depends_on`),
* be shown as tabs of one menu entry (`tab` and `label`),
* use their own update service or render content around the form.

To add a setting to an existing page from a module, use `Settings::Pages.extend_page(:general) { setting :my_setting }`.

### Hand-written pages

Pages too specific for the generic rendering are registered with `custom: true` and keep their own controller and
template. Listing their settings still makes them searchable. Settings changed through something other than a
`settings[<name>]` form field, such as a toggle or a dialog, are registered with `form_field: false`; the element
representing them needs a `data-setting-name` attribute so that the search can highlight it.

`spec/requests/admin/settings/registered_pages_spec.rb` renders every registered page and fails when the settings on
it and the registry differ.

## Settings search

The administration side menu offers a search over all registered settings, structured like the admin menu. Selecting
a setting opens its page with a `highlight` parameter, which `highlight-setting.controller.ts` uses to scroll to and
highlight the setting.
