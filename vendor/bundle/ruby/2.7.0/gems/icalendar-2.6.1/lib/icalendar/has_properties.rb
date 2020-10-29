module Icalendar

  module HasProperties

    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        attr_reader :custom_properties
      end
    end

    def initialize(*args)
      @custom_properties = Hash.new
      super
    end

    def valid?(strict = false)
      self.class.required_properties.each_pair do |prop, validator|
        validator.call(self, send(prop)) or return false
      end
      self.class.mutex_properties.each do |mutexprops|
        mutexprops.map { |p| send p }.compact.size > 1 and return false
      end
      if strict
        self.class.suggested_single_properties.each do |single_prop|
          send(single_prop).size > 1 and return false
        end
      end
      true
    end

    def property(property_name)
      property_name = property_name.downcase
      if self.class.properties.include? property_name
        send property_name
      else
        custom_property property_name
      end
    end

    def custom_property(property_name)
      custom_properties[property_name.downcase] || []
    end

    def append_custom_property(property_name, value)
      property_name = property_name.downcase
      if self.class.single_properties.include? property_name
        send "#{property_name}=", value
      elsif self.class.multiple_properties.include? property_name
        send "append_#{property_name}", value
      elsif value.is_a? Icalendar::Value
        (custom_properties[property_name] ||= []) << value
      else
        (custom_properties[property_name] ||= []) << Icalendar::Values::Text.new(value)
      end
    end

    def method_missing(method, *args, &block)
      method_name = method.to_s
      if method_name.start_with? 'x_'
        if method_name.end_with? '='
          append_custom_property method_name.chomp('='), args.first
        else
          custom_property method_name
        end
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method.to_s.start_with?('x_') || super
    end

    module ClassMethods
      def properties
        single_properties + multiple_properties
      end

      def single_properties
        @single_properties ||= []
      end

      def multiple_properties
        @multiple_properties ||= []
      end

      def required_properties
        @required_properties ||= {}
      end

      def suggested_single_properties
        @suggested_single_properties ||= []
      end

      def mutex_properties
        @mutex_properties ||= []
      end

      def default_property_types
        @default_property_types ||= Hash.new { |h,k| Icalendar::Values::Text }
      end

      def required_property(prop, klass = Icalendar::Values::Text, validator = nil)
        validator ||= ->(component, value) { !value.nil? }
        self.required_properties[prop] = validator
        single_property prop, klass
      end

      def required_multi_property(prop, klass = Icalendar::Values::Text, validator = nil)
        validator ||= ->(component, value) { !value.compact.empty? }
        self.required_properties[prop] = validator
        multi_property prop, klass
      end

      def optional_single_property(prop, klass = Icalendar::Values::Text)
        single_property prop, klass
      end

      def mutually_exclusive_properties(*properties)
        self.mutex_properties << properties
      end

      def optional_property(prop, klass = Icalendar::Values::Text, suggested_single = false)
        self.suggested_single_properties << prop if suggested_single
        multi_property prop, klass
      end

      def single_property(prop, klass)
        self.single_properties << prop.to_s
        self.default_property_types[prop.to_s] = klass

        define_method prop do
          instance_variable_get "@#{prop}"
        end

        define_method "#{prop}=" do |value|
          instance_variable_set "@#{prop}", map_property_value(value, klass, false)
        end
      end

      def multi_property(prop, klass)
        self.multiple_properties << prop.to_s
        self.default_property_types[prop.to_s] = klass
        property_var = "@#{prop}"

        define_method "#{prop}=" do |value|
          mapped = map_property_value value, klass, true
          if mapped.is_a? Icalendar::Values::Array
            instance_variable_set property_var, mapped.to_a.compact
          else
            instance_variable_set property_var, [mapped].compact
          end
        end

        define_method prop do
          if instance_variable_defined? property_var
            instance_variable_get property_var
          else
            send "#{prop}=", nil
          end
        end

        define_method "append_#{prop}" do |value|
          send(prop) << map_property_value(value, klass, true)
        end
      end
    end

    private

    def map_property_value(value, klass, multi_valued)
      if value.nil? || value.is_a?(Icalendar::Value)
        value
      elsif value.is_a? ::Array
        Icalendar::Values::Array.new value, klass, {}, {delimiter: (multi_valued ? ',' : ';')}
      else
        klass.new value
      end
    end

  end
end
