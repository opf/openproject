# Be sure to restart your server when you modify this file.

# For development and non-eager load mode, we need to load models using acts_as_favorable manually
# as no eager loading takes place
Rails.application.config.to_prepare do
  OpenProject::Acts::Favorable::Registry.add(
    Project,
    ProjectQuery,
    reset: true
  )
end
