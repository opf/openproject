---
sidebar_navigation:
  title: Settings search
description: How the settings search in the administration finds settings, actions and entities, and how its registries are kept in sync with the admin pages
keywords: settings search, administration, settings pages, entity kinds, drift spec
---

# Development concept: Settings search

The administration has a search field at the top of its side menu, focused when opening the
administration. While a query is entered, the side menu is replaced by the results: the admin menu as a
tree and, below each menu item, everything that can be found on that page: global settings, actions
such as "New OAuth application", and entities such as work package types with their attributes.
Selecting a node opens the page and, where possible, highlights the setting or field on it. Clearing
the query or pressing Escape brings the menu back.

The admin pages themselves are hand-written views. The search does not inspect them. It relies on two
registries describing what each page shows:

| Registry                  | Declared in                                                            | Describes                                                       |
|---------------------------|------------------------------------------------------------------------|-----------------------------------------------------------------|
| `Settings::Pages`         | `config/initializers/settings_pages.rb` and initializers of the modules | Global settings and actions (links) of each admin page          |
| `Settings::EntityKinds`   | `config/initializers/settings_entity_kinds.rb` and initializers of the modules | Kinds of entities (types, roles, providers, …) and their attributes |

> [!IMPORTANT]
> The registries duplicate what the views render. Whenever you add, rename, move or remove a setting or
> form field on an admin page, update the registry as well. Two drift specs fail when the two disagree,
> see [Keeping the registries in sync](#keeping-the-registries-in-sync).

## Overview of the code

| File                                                       | Purpose                                                              |
|------------------------------------------------------------|----------------------------------------------------------------------|
| `config/constants/settings/pages.rb`                       | The `Settings::Pages` registry DSL                                   |
| `config/constants/settings/entity_kinds.rb`                | The `Settings::EntityKinds` registry DSL                             |
| `app/models/settings/search_tree.rb`                       | Builds and filters the tree from the admin menu and both registries |
| `app/components/admin/settings_search_component.rb`        | The search field at the top of the admin side menu, showing the results instead of the menu |
| `app/components/admin/settings_search/tree_component.rb`   | The tree fragment loaded for a query                                 |
| `frontend/src/stimulus/controllers/dynamic/admin/settings-search.controller.ts` | Swaps the side menu for the results while a query is entered |
| `app/controllers/admin/settings_searches_controller.rb`    | Serves the tree filtered by a query                                  |
| `frontend/src/stimulus/controllers/highlight-setting.controller.ts` | Highlights the element named by the `highlight` parameter   |

## How the tree is built

`Settings::SearchTree` walks the admin menu (`Redmine::MenuManager.items(:admin_menu)`):

- Every visible admin menu item becomes a node linking to its page, even when nothing is registered for
  it. Menu items whose `if:` condition fails or which are hidden through the `hidden_menu_items`
  configuration are left out together with everything below them. This is also how permissions and
  feature flags apply: a page that is not in the menu is not in the search.
- Below a menu item, the tree lists the settings and links of the pages registered for it, then the
  attributes and matching entities of its entity kinds, then its child menu items.
- Pages with a `label` become a node of their own, e.g. the tabs of a page.

The search runs on the server. The query is split into words, ignoring case and punctuation, so
"self registration" finds "Self-registration". A node matches when every query word is contained in the
words of the node's label, its description (the setting's caption) or the labels of its ancestors. All
nodes below a matching node stay visible, so "passwords" lists every setting of the passwords tab.

The tree without the entities matching a query (the menu structure, all settings and the attributes of
the entity kinds) is cached for every admin, locale and state of the settings, as building it is
expensive: it translates all settings and loads an example entity per kind. Only the entities matching
a query are looked up per request. Entities added or renamed are found all the same; only the entity an
attribute links to may be outdated until the cache expires (one minute).

## Registering a settings page

Pages are drawn with `Settings::Pages.draw`. Each page references the admin menu item it is shown under:

```ruby
Settings::Pages.draw do
  page :general, menu_item: :settings_general do
    setting :app_title
    setting :host_name,
            caption: -> { "#{t(:label_example)}: #{request.host_with_port}" }

    setting :security_badge_displayed, if: -> { OpenProject::Configuration.security_badge_displayed? }
  end

  page :mail_notifications, menu_item: :mail_notifications do
    section :mails, if: -> { ActionMailer::Base.perform_deliveries } do
      setting :mail_from
    end
  end
end
```

- `setting` lists a global setting shown on the page. It must have a `Settings::Definition`.
- `label:` and `caption:` default to the `setting_<name>` and `setting_<name>_caption(_html)`
  translations. Give them when the page shows a different text, so that the search shows what the user
  sees. Both accept a translation key, a string or a lambda evaluated in the view context.
- `if:` on a setting, section or page hides it when the condition fails, e.g. when the page only shows a
  setting in a certain configuration. Sections only exist to share such a condition.
- `url:` points to another controller than the menu item's, e.g. a tab served by its own controller.

Modules register their pages in an initializer of their engine and may extend existing pages:

```ruby
initializer "my_module.settings_search" do
  ::Settings::Pages.draw do
    page :my_module, menu_item: :my_module_settings do
      setting :my_module_setting
    end
  end

  ::Settings::Pages.extend_page(:general) do
    setting :my_plugin_setting
  end
end
```

Registrations referencing model constants (e.g. to loop over provider types) must run in
`config.after_initialize`, as constants cannot be autoloaded while initializers run.

### Tabs

Pages sharing a menu item and having a `label` are listed as tabs of that menu item. The `tab` is added
to the URL as the `tab` parameter:

```ruby
page :authentication_passwords,
     menu_item: :authentication_settings,
     tab: "passwords",
     label: :"settings.passwords" do
  setting :password_min_length
end
```

A tab served by a different controller gives its `url:` instead of a `tab:`.

## Highlighting a setting on its page

Settings link to their page with a `highlight` parameter, e.g. `/admin/settings/general?highlight=host_name`.
The `highlight-setting` Stimulus controller, attached to the `body` of every page, looks for the element to highlight,
scrolls to it and removes the parameter from the URL. It understands:

| `highlight` value             | Highlights                                                                 |
|-------------------------------|----------------------------------------------------------------------------|
| `host_name`                   | The element with `data-setting-name="host_name"`, otherwise the `settings[host_name]` field |
| `type[color_id]`              | The form field with that name                                              |
| `role[permissions][]=edit_project` | The input of that field having the given value, e.g. one check box of a group |
| `webhook_secret`              | Falls back to a field named exactly `webhook_secret` if no `settings[webhook_secret]` field exists |

The highlight wraps the field's form control, so the label and caption are highlighted with it.

### Settings in other fields than `settings[<name>]`

Some pages submit a setting in a differently named field, e.g. the keys of a plugin's settings hash or
unscoped fields. Register the field:

```ruby
setting :plugin_openproject_github_integration,
        field: "webhook_secret",
        label: :label_github_webhook_secret
```

The same setting may be listed several times with different fields.

### Settings without a form field

Settings changed through a toggle, a dialog, a JavaScript component or an inline edit have no
`settings[<name>]` field in the rendered page. Register them with `form_field: false` and mark the
element representing them in the view with `data-setting-name`:

```ruby
setting :real_time_text_collaboration_enabled, form_field: false
```

```erb
<a class="PageHeader-action" data-setting-name="real_time_text_collaboration_enabled">
  <span class="Button-content">
    <span class="Button-label">Disable</span>
  </span> 
</a>
```

In Primer forms, pass the marker as data of the input or group representing the setting:

```ruby
sf.fieldset_group(title: I18n.t(:setting_project_gantt_query),
                  data: { setting_name: "project_gantt_query" }) do |fg|
  # …
end
```

When the entry has a `field:`, the marker uses that field instead of the setting's name.

## Actions: links to "new entity" pages

Pages register their actions as links. A link opens its URL directly without highlighting:

```ruby
page :oauth_applications, menu_item: :oauth_applications do
  link :new, label: :"oauth.application.new", url: -> { new_oauth_application_path }
end
```

- `url:` is a lambda evaluated in the view context, so route helpers and parameters can be used, e.g.
  one link per provider type: `new_openid_connect_provider_path(oidc_provider: type)`.
- `if:` hides the link, e.g. when the enterprise feature required by the button is not available, so
  that the search does not lead to a page refusing the action.
- `label:` may be a lambda, e.g. to show "Reset backup token" instead of "Create backup token".

Actions opening a dialog through a Turbo Stream request (e.g. "Add Enterprise token") cannot be opened
by a link. Link to the page showing the button instead.

## Entities and their attributes

Entities such as work package types, roles or OpenID providers are registered as entity kinds. A kind
lists its attributes below its menu item once, leading to the attribute on the first entity it applies
to. Entities themselves are only listed when their name matches a word of the query, at most
`Settings::EntityKinds::MATCH_LIMIT` per kind, so that instances with thousands of entities keep a
usable tree. "work package type bug color" therefore lists the color of the type "Bug".

```ruby
Settings::EntityKinds.draw do
  kind :types, menu_item: :types, scope: -> { Type.order(:position) },
               url: ->(type) { edit_type_details_path(type) } do
    attribute :color, label: -> { Color.model_name.human }, field: "type[color_id]"
    attribute :form_configuration,
              label: :"types.edit.form_configuration.tab",
              url: ->(type) { edit_type_form_configuration_path(type) }
  end
end
```

- `scope:` lists the entities, `name:` names the column matched against the query (default `:name`) and
  `url:` the page of an entity.
- `field:` names the form field to highlight on the entity's page, in the formats listed under
  [Highlighting](#highlighting-a-setting-on-its-page). Without a field, the attribute just opens the page.
- `url:` on an attribute leads to another page or tab of the entity, e.g. the form configuration tab of
  a type or a section of an OpenID provider (`edit_openid_connect_provider_path(provider, edit_state: :client_details)`).
- `if:` on an attribute receives the entity and limits the entities the attribute applies to, e.g. a
  custom field's minimum and maximum length only for formats having a length. Attributes of edit pages showing
  sections in display mode (e.g. storages) are registered without a field.
- `group:` nests attributes below a common node, e.g. the permissions of a role.
- `attributes_from` builds attributes lazily, e.g. one per permission.
- `if:` on the kind hides the kind altogether, e.g. without the enterprise feature required to edit its
  entities.

Single records shown like settings, such as the switch enabling project wikis
(`Wikis::InternalProvider`) or the announcement, are registered as kinds with a single entity.

## Keeping the registries in sync

The views and the registries must describe the same settings and fields. Nothing derives one from the
other, so they drift apart whenever a view is changed without updating the registry, or the other way
round. The search then lists settings that do not exist on the page, links to the wrong page, highlights
nothing or misses settings entirely.

Two request specs render the admin pages and compare them with the registries. They are the safety net
for every change to an admin page and must pass:

### `spec/requests/admin/settings/registered_pages_spec.rb`

Renders every registered page that lists settings and checks, per page:

- The `settings[<name>]` fields of defined settings in the page are exactly the registered settings
  without `field:` or `form_field: false`. A setting rendered but not registered fails the spec just
  like a registered setting no longer rendered.
- Every registered `field:` is rendered.
- Every setting registered with `form_field: false` has its `data-setting-name` marker in the page.

The pages are rendered twice, the second time with optional states enabled (e.g. a pending version
conversion or an enabled collaboration server), so that settings shown conditionally are checked as
well. When you add a setting that is only shown in a certain state, register it with a matching `if:`
and, if necessary, enable that state in the spec.

### `spec/requests/admin/settings/entity_attributes_spec.rb`

Creates entities of every kind and renders each page an attribute leads to, checking that every
registered `field:` is present there. Add an entry for every new kind with attributes that have fields.

### What the specs do not check

- Labels and captions. Check that the search shows the texts of the page.
- Links. Check that each link opens the intended page.
- Menu items without registered settings, which are listed automatically.

### Checklist when changing an admin page

1. Adding a setting to a page: register it with `setting` on that page, with `label:`/`caption:` if the
   page shows other texts than the setting's translations.
2. Rendering a setting through something other than a `settings[<name>]` field: register its `field:`,
   or use `form_field: false` and add a `data-setting-name` marker.
3. Adding a button creating an entity: register a `link`, conditioned like the button.
4. Adding or renaming a field of an entity's form: update the attribute's `field:` in its kind.
5. Run both drift specs and `spec/models/settings/search_tree_spec.rb`.

### Future work

In the future, we should use a generic controller (which may use custom update contracts),
and generate all UI automatically based on the settings pages and entity kinds structures,
so that adding a new setting, or entity attributes only have to be registered,
and no new controllers, contracts, or templates have to be written by default.

