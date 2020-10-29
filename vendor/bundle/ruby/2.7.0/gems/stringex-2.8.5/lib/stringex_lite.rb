# encoding: UTF-8

require 'ostruct'
require 'stringex/configuration'
require 'stringex/localization'
require 'stringex/string_extensions'
require 'stringex/unidecoder'
require 'stringex/version'

String.send :include, Stringex::StringExtensions::PublicInstanceMethods
String.send :extend, Stringex::StringExtensions::PublicClassMethods

if defined?(Rails::Railtie)
  require 'stringex/rails/railtie'
end
