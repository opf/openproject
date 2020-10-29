require 'spreadsheet/compatibility'

module Spreadsheet
  module Excel
##
# This module is used to keep track of offsets in modified Excel documents.
# Considered internal and subject to change without notice.
module Offset
  include Compatibility
  attr_reader :changes, :offsets
  def initialize *args
    super
    @changes = {}
    @offsets = {}
  end
  def Offset.append_features mod
    super
    mod.module_eval do
      class << self
        include Compatibility
        def offset *keys
          keys.each do |key|
            attr_reader key unless instance_methods.include? method_name(key)
            define_method "#{key}=" do |value|
              @changes.store key, true
              instance_variable_set ivar_name(key), value
            end
            define_method "set_#{key}" do |value, pos, len|
              instance_variable_set ivar_name(key), value
              @offsets.store key, [pos, len]
              havename = "have_set_#{key}"
              send(havename, value, pos, len) if respond_to? havename
            end
          end
        end
      end
    end
  end
end
  end
end
