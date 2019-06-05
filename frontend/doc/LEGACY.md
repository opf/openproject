# Additional information on Legacy frontend

The legacy bundle is only used from Rails to add functionality to specific parts of the application.

## Loading and bootstrapping the legacy AngularJS frontend

To bootstrap the AngularJS frontend from Rails, use the `activate_angular_js` helper block:

```html
<!-- @see ./app/helpers/angular_helper.rb -->
<%= activate_angular_js do %>
    <persistent-toggle identifier="repository.checkout_instructions">
      <div>
      Something rendered from Rails ...
    </div>
    </persistent-toggle>
<% end %>
```

The legacy frontend with AngularJS can be bootstrapped _with_ content contained within. This is not possible in Angular,
since the root component needs to be empty (or will be emptied during bootstrap).

## Passing information and configuration from Rails to Angular

There are three ways of passing information from Rails to `AngularJS`:

1. Using tag attributes written directly to the DOM by the rendering process of Rails as in the example before.

2. Using  the `gon` gem

This is included by all layouts in `<head>`:

```js
<%= nonced_javascript_tag do %>
  <%= include_gon(need_tag: false) -%>
<% end %>
```

`gon` will provide arbitrary settings from Rails to all JavaScript functionality, including `AngularJS`. In an `angular` context a `ConfigurationService` is provided for picking up the settings.
