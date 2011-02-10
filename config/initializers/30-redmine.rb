I18n.default_locale = 'en'
# Adds fallback to default locale for untranslated strings
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

require 'redmine'
