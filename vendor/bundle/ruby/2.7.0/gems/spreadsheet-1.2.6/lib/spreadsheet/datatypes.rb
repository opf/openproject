require 'spreadsheet/compatibility'

module Spreadsheet
  ##
  # This module defines convenience-methods for the definition of Spreadsheet
  # attributes (boolean, colors and enumerations)
  module Datatypes
    include Compatibility
    def Datatypes.append_features mod
      super
      mod.module_eval do
class << self
  ##
  # Valid colors for color attributes.
  COLORS = [ :builtin_black, :builtin_white, :builtin_red, :builtin_green,
             :builtin_blue, :builtin_yellow, :builtin_magenta, :builtin_cyan,
             :text, :border, :pattern_bg, :dialog_bg, :chart_text, :chart_bg,
             :chart_border, :tooltip_bg, :tooltip_text, :aqua,
             :black, :blue, :cyan, :brown, :fuchsia, :gray, :grey, :green,
             :lime, :magenta, :navy, :orange, :purple, :red, :silver, :white,
             :yellow,
             :xls_color_0,
             :xls_color_1,
             :xls_color_2,
             :xls_color_3,
             :xls_color_4,
             :xls_color_5,
             :xls_color_6,
             :xls_color_7,
             :xls_color_8,
             :xls_color_9,
             :xls_color_10,
             :xls_color_11,
             :xls_color_12,
             :xls_color_13,
             :xls_color_14,
             :xls_color_15,
             :xls_color_16,
             :xls_color_17,
             :xls_color_18,
             :xls_color_19,
             :xls_color_20,
             :xls_color_21,
             :xls_color_22,
             :xls_color_23,
             :xls_color_24,
             :xls_color_25,
             :xls_color_26,
             :xls_color_27,
             :xls_color_28,
             :xls_color_29,
             :xls_color_30,
             :xls_color_31,
             :xls_color_32,
             :xls_color_33,
             :xls_color_34,
             :xls_color_35,
             :xls_color_36,
             :xls_color_37,
             :xls_color_38,
             :xls_color_39,
             :xls_color_40,
             :xls_color_41,
             :xls_color_42,
             :xls_color_43,
             :xls_color_44,
             :xls_color_45,
             :xls_color_46,
             :xls_color_47,
             :xls_color_48,
             :xls_color_49,
             :xls_color_50,
             :xls_color_51,
             :xls_color_52,
             :xls_color_53,
             :xls_color_54,
             :xls_color_55 ]
  ##
  # Define instance methods to read and write boolean attributes.
  def boolean *args
    args.each do |key|
      define_method key do
        name = ivar_name key
        !!(instance_variable_get(name) if instance_variables.include?(name))
      end
      define_method "#{key}?" do
        send key
      end
      define_method "#{key}=" do |arg|
        arg = false if arg == 0
        instance_variable_set(ivar_name(key), !!arg)
      end
      define_method "#{key}!" do
        send "#{key}=", true
      end
    end
  end
  ##
  # Define instance methods to read and write color attributes.
  # For valid colors see COLORS
  def colors *args
    args.each do |key|
      attr_reader key
      define_method "#{key}=" do |name|
        name = name.to_s.downcase.to_sym
        if COLORS.include?(name)
          instance_variable_set ivar_name(key), name
        else
          raise ArgumentError, "unknown color '#{name}'"
        end
      end
    end
  end
  ##
  # Define instance methods to read and write enumeration attributes.
  # * The first argument designates the attribute name.
  # * The second argument designates the default value.
  # * All subsequent attributes are possible values.
  # * If the last attribute is a Hash, each value in the Hash designates
  #   aliases for the corresponding key.
  def enum key, *values
    aliases = {}
    if values.last.is_a? Hash
      values.pop.each do |value, synonyms|
        if synonyms.is_a? Array
          synonyms.each do |synonym| aliases.store synonym, value end
        else
          aliases.store synonyms, value
        end
      end
    end
    values.each do |value|
      aliases.store value, value
    end
    define_method key do
      name = ivar_name key
      value = instance_variable_get(name) if instance_variables.include? name
      value || values.first
    end
    define_method "#{key}=" do |arg|
      if arg
        arg = aliases.fetch arg do
          aliases.fetch arg.to_s.downcase.gsub(/[ \-]/, '_').to_sym, arg
        end
        if values.any? do |val| val === arg end
          instance_variable_set(ivar_name(key), arg)
        else
          valid = values.collect do |val| val.inspect end.join ', '
          raise ArgumentError,
            "Invalid value '#{arg.inspect}' for #{key}. Valid values are: #{valid}"
        end
      else
        instance_variable_set ivar_name(key), values.first
      end
    end
  end
end
      end
    end
  end
end
