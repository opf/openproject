Recaptcha.configure do |config|
  # site_key and secret_key are defined via ENV already (RECAPTCHA_SITE_KEY, RECAPTCHA_SECRET_KEY)

  config.verify_url = OpenProject::Recaptcha.verify_url_override || config.verify_url
  config.api_server_url = OpenProject::Recaptcha.api_server_url_override || config.api_server_url
end

module RecaptchaLimitOverride
  def invalid_response?(resp)
    return super unless OpenProject::Recaptcha::use_hcaptcha?

    resp.empty? || resp.length > ::OpenProject::Recaptcha.hcaptcha_response_limit
  end
end

Recaptcha.singleton_class.prepend RecaptchaLimitOverride
