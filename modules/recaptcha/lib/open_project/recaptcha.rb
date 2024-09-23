module OpenProject
  module Recaptcha
    TYPE_DISABLED ||= "disabled"
    TYPE_V2 ||= "v2"
    TYPE_V3 ||= "v3"
    TYPE_HCAPTCHA ||= "hcaptcha"
    TYPE_TURNSTILE ||= "turnstile"

    require "open_project/recaptcha/engine"
    require "open_project/recaptcha/configuration"

    extend Configuration
  end
end
