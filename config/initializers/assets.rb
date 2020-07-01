OpenProject::Application.configure do
  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w(
    favicon.ico
    admin_users.js
    locales/*.js
    members_form.js
    new_user.js
    project/responsible_attribute.js
    project/description_handling.js
    project/filters.js
    repository_navigation.js
    repository_settings.js
    vendor/ckeditor/ckeditor.*js
    vendor/enjoyhint.js
  )
end
