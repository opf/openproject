OpenProject::Application.configure do
  config.assets.precompile += %w(
    favicon.ico
    locales/*.js
    openapi-explorer.min.js
    @primer/view-components/app/assets/javascripts/primer_view_components.js
  )
end
