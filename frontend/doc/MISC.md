Additional hints
================

## Passing information and configuration from Rails to Angular

There are three ways of passing information from Rails to `angular`:

1. Using tag attributes written directly to the DOM by the rendering process of Rails:

```html
<!-- @see ./app/views/layouts/angular.html.erb -->
<body class="<%= body_css_classes %>" ng-app="openproject" data-relative_url_root="<%= root_path %>" ng-init="projectIdentifier = '<%= (@project.identifier rescue '') %>'">
<!-- [..] -->
</body>
```

2. Using  the `gon` gem

This is included by all layouts in `<head>`:

```
<%= include_gon(nonce: content_security_policy_nonce(:script)) %>
```

`gon` will provide arbitrary settings from Rails to all JavaScript functionality, including `angular`. In an `angular` context a `ConfigurationService` is provided for picking up the settings.

3. From the APIv3

APIv3 introduces a settings endpoint which can be used to query settings from the API directly (see [here for more information](http://opf.github.io/apiv3-doc/#configuration)). This is useful for querying user specific settings and guarded information. _The endpoint is not complete at the time of writing_

The only place this is currently used is within the `ConfigurationService`, which provides an `api`, which can be used like this:

```javascript
// angular injected

function(ConfigurationService) {
    ConfigurationService.api().then(function(settings) {
        console.log(settings);
    })
}

// from the outside
angular
    .element('body')
    .injector()
    .invoke([
        'ConfigurationService', 
        function(service) {
            service.api().then(function(settings) {
                console.log(settings);
            })
        }
    ])
```

Calls to the API are cached between page reloads. It would be advisable to cache them longer (e.g. in `localStorage`) in the future, as the data rarely updates.
