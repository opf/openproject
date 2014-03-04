if ENV['AIRBRAKE_API_KEY']
  Airbrake.configure do |config|
    config.api_key = ENV['AIRBRAKE_API_KEY']
    config.host    = ENV['AIRBRAKE_HOST']
    config.port    = 443
    config.secure  = config.port == 443

    config.rescue_rake_exceptions = true
    # config.development_environments = []
  end
end