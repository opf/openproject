# load custom translation rules, as stored in config/locales/plurals.rb
# to be aware of e.g. Japanese not having a plural from for nouns
require "open_project/translations/pluralization_backend"
I18n::Backend::Simple.include OpenProject::Translations::PluralizationBackend

# Adds fallback to default locale for untranslated strings
I18n::Backend::Simple.include I18n::Backend::Fallbacks

Rails.application.reloader.to_prepare do
  # As we enabled +config.i18n.fallbacks+, Rails will fall back
  # to the default locale.
  # When other locales are available, fall back to them.
  if Setting.table_exists? # don't want to prevent migrations
    defaults = Set.new(I18n.fallbacks.defaults + Redmine::I18n.valid_languages.map(&:to_sym))
    I18n.fallbacks.defaults = defaults
  end
end
