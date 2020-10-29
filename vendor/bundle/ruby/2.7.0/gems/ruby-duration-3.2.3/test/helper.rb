# -*- encoding:  utf-8 -*-
require 'rubygems'
require 'minitest/autorun'
begin
  require 'simplecov'
  SimpleCov.start do
  end
rescue LoadError
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'i18n'
I18n.enforce_available_locales = true

require 'ruby-duration'
