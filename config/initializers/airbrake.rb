airbrake = OpenProject::Configuration['airbrake']

if airbrake && airbrake['api_key']
  Airbrake.configure do |config|
    config.api_key = airbrake['api_key']
    config.host    = airbrake['host'] if airbrake['host']
    config.port    = Integer(airbrake['port'] || 443)
    config.secure  = config.port == 443
  end
end
