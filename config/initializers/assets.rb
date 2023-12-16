# Be sure to restart your server when you modify this file.

OpenProject::Application.configure do
  # Version of your assets, change this if you want to expire all your assets.
  # config.assets.version = "1.0"

  # Add additional assets to the asset load path.
  # config.assets.paths << Emoji.images_path

  # Precompile additional assets.
  # application.js, application.css, and all non-JS/CSS in the app/assets
  # folder are already added.
  config.assets.precompile += %w(
    favicon.ico
    locales/*.js
    openapi-explorer.min.js
  )
end
