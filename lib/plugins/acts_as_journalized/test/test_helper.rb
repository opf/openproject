#-- encoding: UTF-8
$: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'shoulda'
require 'mocha/setup'
require 'vestal_versions'
require 'schema'
begin; require 'redgreen'; rescue LoadError; end
