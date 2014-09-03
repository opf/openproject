if ENV['AIRBRAKE_API_KEY']
  Airbrake.configure do |config|
    config.api_key = ENV.fetch('AIRBRAKE_API_KEY')
    config.host    = ENV['AIRBRAKE_HOST'] if ENV['AIRBRAKE_HOST']
    config.port    = ENV.fetch('AIRBRAKE_PORT', 443)
    config.secure  = config.port == 443

    config.rescue_rake_exceptions = true
    # config.development_environments = []
  end
end
