module RecaptchaHelper
  def recaptcha_available_options
    [
      [I18n.t("recaptcha.settings.type_disabled"), ::OpenProject::Recaptcha::TYPE_DISABLED],
      [I18n.t("recaptcha.settings.type_v2"), ::OpenProject::Recaptcha::TYPE_V2],
      [I18n.t("recaptcha.settings.type_v3"), ::OpenProject::Recaptcha::TYPE_V3],
      [I18n.t("recaptcha.settings.type_hcaptcha"), ::OpenProject::Recaptcha::TYPE_HCAPTCHA],
      [I18n.t("recaptcha.settings.type_turnstile"), ::OpenProject::Recaptcha::TYPE_TURNSTILE]

    ]
  end

  def recaptcha_settings
    Setting.plugin_openproject_recaptcha
  end
end
