# Be sure to restart your server when you modify this file.

# For development and non-eager load mode, we need to load models using acts_as_watchable manually
# as no eager loading takes place
Rails.application.config.to_prepare do
  OpenProject::Acts::Watchable::Registry.add(
    Forum,
    Meeting,
    Message,
    News,
    Wiki,
    WikiPage,
    WorkPackage,
    reset: true
  )
end
