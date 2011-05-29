#-- copyright
# ChiliProject is a project management system.
# 
# Copyright (C) 2010-2011 the ChiliProject Team
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine
  class CustomFieldFormat
    include Redmine::I18n

    cattr_accessor :available
    @@available = {}

    attr_accessor :name, :order, :label, :edit_as, :class_names

    def initialize(name, options={})
      self.name = name
      self.label = options[:label]
      self.order = options[:order]
      self.edit_as = options[:edit_as] || name
      self.class_names = options[:only]
    end

    def format(value)
      send "format_as_#{name}", value
    end

    def format_as_date(value)
      begin; format_date(value.to_date); rescue; value end
    end

    def format_as_bool(value)
      l(value == "1" ? :general_text_Yes : :general_text_No)
    end

    ['string','text','int','float','list'].each do |name|
      define_method("format_as_#{name}") {|value|
        return value
      }
    end
    
    ['user', 'version'].each do |name|
      define_method("format_as_#{name}") {|value|
        return value.blank? ? "" : name.classify.constantize.find_by_id(value.to_i).to_s
      }
    end

    class << self
      def map(&block)
        yield self
      end
      
      # Registers a custom field format
      def register(custom_field_format, options={})
        @@available[custom_field_format.name] = custom_field_format unless @@available.keys.include?(custom_field_format.name)
      end

      def available_formats
        @@available.keys
      end

      def find_by_name(name)
        @@available[name.to_s]
      end

      def label_for(name)
        format = @@available[name.to_s]
        format.label if format
      end

      # Return an array of custom field formats which can be used in select_tag
      def as_select(class_name=nil)
        fields = @@available.values
        fields = fields.select {|field| field.class_names.nil? || field.class_names.include?(class_name)}
        fields.sort {|a,b|
          a.order <=> b.order
        }.collect {|custom_field_format|
          [ l(custom_field_format.label), custom_field_format.name ]
        }
      end

      def format_value(value, field_format)
        return "" unless value && !value.empty?

        if format_type = find_by_name(field_format)
          format_type.format(value)
        else
          value
        end
      end
    end
  end 
end
