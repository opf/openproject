OpenProject::Application.configure do
  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w(
    favicon.ico
    openproject.css
    accessibility.css
    accessibility.js
    admin_users.js
    autocompleter.js
    calendar/lang/*.js
    contextual_fieldset.js
    copy_issue_actions.js
    date-de-DE.js
    date-en-US.js
    locales/*.js
    members_form.js
    members_select_boxes.js
    my_page.js
    new_user.js
    project/responsible_attribute.js
    project/description_handling.js
    project/filters.js
    repository_navigation.js
    repository_settings.js
    select_list_move.js
    types_checkboxes.js
    work_packages.js
    vendor/ckeditor/ckeditor.*js
    bundles/openproject-legacy-app.js
  )
end
