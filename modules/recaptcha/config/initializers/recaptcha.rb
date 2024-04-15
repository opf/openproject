module RecaptchaLimitOverride
  def invalid_response?(resp)
    return super unless OpenProject::Recaptcha::use_hcaptcha?

    resp.empty? || resp.length > ::OpenProject::Recaptcha.hcaptcha_response_limit
  end
end

Recaptcha.singleton_class.prepend RecaptchaLimitOverride
