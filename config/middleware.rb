require 'request_headers'

if %w(test).include?(Rails.env)
  Rails.application.config.middleware.insert_before Rack::Lock, "RequestHeaders", CustomHeadersHelper
end