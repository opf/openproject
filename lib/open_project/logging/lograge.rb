module OpenProject
  module Logging
    module Lograge
      def self.enabled?
        OpenProject::Configuration.lograge_formatter.present?
      end

      def self.formatter_class
        formatter_setting = OpenProject::Configuration.lograge_formatter || 'key_value'

        "Lograge::Formatters::#{formatter_setting.classify}".constantize
      end
    end
  end
end
