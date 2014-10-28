module OpenProject::RoutedExceptions
  module RailsConfigurationPatch
    def self.included(base)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def routed_exceptions
        @routed_exceptions_config ||= OpenProject::RoutedExceptions::Configuration.new(self)
      end
    end
  end
end

unless Rails::Application::Configuration.included_modules.include?(OpenProject::RoutedExceptions::RailsConfigurationPatch)
  Rails::Application::Configuration.include(OpenProject::RoutedExceptions::RailsConfigurationPatch)
end
