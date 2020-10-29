# encoding: UTF-8

require 'ostruct'
require 'stringex/configuration'
require 'stringex/localization'
require 'stringex/string_extensions'
require 'stringex/unidecoder'
require 'stringex/acts_as_url'
require 'stringex/version'

require 'stringex/core_ext'

Stringex::ActsAsUrl::Adapter.load_available

if defined?(Rails::Railtie)
  require 'stringex/rails/railtie'
end
