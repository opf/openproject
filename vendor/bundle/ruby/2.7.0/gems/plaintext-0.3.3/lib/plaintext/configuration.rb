# frozen_string_literal: true

module Plaintext
  module Configuration
    class << self
      attr_accessor :config

      # Returns a configuration setting
      def [](name)
        load if self.config.nil?
        self.config[name]
      end

      def load(config_file = nil)
        self.config = {}
        return unless config_file

        file_config = YAML::load(ERB.new(config_file).result)
        if file_config.is_a?(Hash)
          self.config = file_config
        else
          warn "`config_file` is not a valid Plaintext configuration file, ignoring."
        end
      end
    end
  end
end