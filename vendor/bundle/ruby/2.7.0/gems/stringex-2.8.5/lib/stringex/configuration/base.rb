module Stringex
  module Configuration
    class Base
      attr_accessor :settings

      def initialize(local_options = {})
        current_settings = default_settings.merge(system_wide_customizations)
        current_settings.merge! local_options

        @settings = OpenStruct.new(current_settings)
      end

      # NOTE: This does not cache itself so that instance and class can be cached on the adapter
      # without worrying about thread safety or race conditions
      def adapter
        adapter_name = settings.adapter || Stringex::ActsAsUrl::Adapter.first_available
        case adapter_name
        when Class
          adapter_name.send :new, self
        when :active_record
          Stringex::ActsAsUrl::Adapter::ActiveRecord.new self
        when :mongoid
          Stringex::ActsAsUrl::Adapter::Mongoid.new self
        else
          raise ArgumentError, "#{adapter_name} is not a defined ActsAsUrl adapter. Please feel free to implement your own and submit it back upstream."
        end
      end

      def self.configure(&block)
        configurator = Stringex::Configuration::Configurator.new(self)
        yield configurator
      end

      def self.system_wide_customizations
        @system_wide_customizations ||= {}
      end

      def self.unconfigure!
        @system_wide_customizations = {}
      end

    private

      def default_settings
        raise ArgumentError, "You shouldn't have hit default_settings on Stringex::Configuration::Base. Check your code."
      end

      def system_wide_customizations
        self.class.system_wide_customizations
      end

      def self.valid_configuration_details
        default_settings.keys
      end
    end
  end
end

