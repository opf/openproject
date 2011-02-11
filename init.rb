fail "upgrade ruby version, ruby < 1.8.7 suffers from Hash#hash bug" if {:a => 10}.hash != {:a => 10}.hash
#require "hwia_rails"

require 'big_decimal_patch'
require 'to_date_patch'

if Rails.version.start_with? "3"
  config.middleware.use ::ActionDispatch::Static, "#{root}/assets"
end
