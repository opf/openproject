OpenProject::Application.configure do
  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w(
    favicon.ico
    openproject.css
    accessibility.css
    admin_users.js
    autocompleter.js
    copy_issue_actions.js
    date-de-DE.js
    date-en-US.js
    locales/*.js
    members_form.js
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
    vendor/enjoyhint.js
  )
end
