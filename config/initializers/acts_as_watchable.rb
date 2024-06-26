# Be sure to restart your server when you modify this file.

# For development and non-eager load mode, we need to load models using acts_as_watchable manually
# as no eager loading takes place
Rails.application.config.after_initialize do
  Forum
  Meeting
  Message
  News
  Wiki
  WikiPage
  WorkPackage
end
