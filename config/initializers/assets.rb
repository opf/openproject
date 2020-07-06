OpenProject::Application.configure do
  config.assets.precompile += %w(
    favicon.ico
    locales/*.js
  )
end
