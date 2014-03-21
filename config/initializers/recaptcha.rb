Recaptcha.configure do |config|
  config.skip_verify_env << 'development'
end if defined? Recaptcha
