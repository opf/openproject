# Be sure to restart your server when you modify this file.

# For development and non-eager load mode, we need to load models using acts_as_favorable manually
# as no eager loading takes place
Rails.application.config.after_initialize do
  Project
end
