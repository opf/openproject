OpenProject::Application.configure do
  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
  config.assets.precompile += %w(
    favicon.ico
    admin_users.js
    locales/*.js
    new_user.js
    project/responsible_attribute.js
    project/description_handling.js
    project/filters.js
    vendor/ckeditor/ckeditor.*js
    vendor/enjoyhint.js
  )
end
