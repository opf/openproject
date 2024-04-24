# Auto-build js translations in dev mode
Rails.application.config.after_initialize do
  if Rails.env.development?
    require "i18n-js/listen"
    I18nJS.listen
  end
end
