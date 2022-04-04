#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

module Settings
  class Definition
    ENV_PREFIX = 'OPENPROJECT_'.freeze

    attr_accessor :name,
                  :format

    attr_writer :value,
                :allowed

    def initialize(name,
                   value:,
                   format: nil,
                   writable: true,
                   allowed: nil)
      self.name = name.to_s
      self.format = format ? format.to_sym : deduce_format(value)
      self.value = value
      self.writable = writable
      self.allowed = allowed
    end

    def value
      return nil if @value.nil?

      case format
      when :integer
        @value.to_i
      when :float
        @value.to_f
      when :boolean
        @value.is_a?(Integer) ? ActiveRecord::Type::Boolean.new.cast(@value) : @value
      when :symbol
        @value.to_sym
      else
        if @value.respond_to?(:call)
          @value.call
        else
          @value
        end
      end
    end

    def serialized?
      %i[array hash].include?(format)
    end

    def writable?
      if writable.respond_to?(:call)
        writable.call
      else
        !!writable
      end
    end

    def override_value(other_value)
      if format == :hash
        self.value = {} if value.nil?
        value.deep_merge! other_value
      else
        self.value = other_value
      end

      raise ArgumentError, "Value for #{name} must be one of #{allowed.join(', ')} but is #{value}" unless valid?

      self.writable = false
    end

    def valid?
      # TODO: it would make sense to also check the type of the value (e.g. boolean).
      # But as using e.g. 0 for a boolean is quite common, that would break.
      !allowed ||
        (format == :array && (value - allowed).empty?) ||
        allowed.include?(value)
    end

    def allowed
      if @allowed.respond_to?(:call)
        @allowed.call
      else
        @allowed
      end
    end

    class << self
      # Adds a setting definition to the set of configured definitions. A definition will define a name and a default value.
      # However, that value can be overwritten by (lower tops higher):
      # * a value stored in the database (`settings` table)
      # * a value in the config/configuration.yml file
      # * a value provided by an ENV var
      #
      # @param [Object] name The name of the definition
      # @param [Object] value The default value the setting has if not overwritten.
      # @param [nil] format The format the value is in e.g. symbol, array, hash, string. If a value is present,
      #  the format is deferred.
      # @param [TrueClass] writable Whether the value can be set in the UI. In case the value is set via file or ENV var,
      #  this will be set to false later on and UI elements that refer to the definition will be disabled.
      # @param [nil] allowed The array of allowed values that can be assigned to the definition.
      #  Will serve to be validated against. A lambda can be provided returning an array in case
      #  the array needs to be evaluated dynamically. In case of e.g. boolean format, setting
      #  an allowed array is not necessary.
      def add(name,
              value:,
              format: nil,
              writable: true,
              allowed: nil)
        return if @by_name.present? && @by_name[name.to_s].present?

        @by_name = nil

        definition = new(name,
                         format: format,
                         value: value,
                         writable: writable,
                         allowed: allowed)

        override_value(definition)

        all << definition
      end

      def define(&block)
        instance_exec(&block)
      end

      def [](name)
        by_name[name.to_s]
      end

      def exists?(name)
        by_name.keys.include?(name.to_s)
      end

      def all_of_prefix(prefix)
        all.select { |definition| definition.name.start_with?(prefix) }
      end

      def all
        @all ||= []

        unless loaded
          self.loaded = true
          load './config/constants/settings/definitions.rb'
        end

        @all
      end

      private

      # Currently only required for testing
      def reset
        @all = nil
        @loaded = false
        @by_name = nil
        @file_config = nil
      end

      def by_name
        @by_name ||= all.index_by(&:name)
      end

      def file_config
        @file_config ||= begin
          filename = Rails.root.join('config/configuration.yml')

          file_config = {}

          if File.file?(filename)
            file_config = load_yaml(ERB.new(File.read(filename)).result)

            if file_config.is_a? Hash
              file_config
            else
              warn "#{filename} is not a valid OpenProject configuration file, ignoring."
            end
          end

          file_config
        end
      end

      # Replace values for which an entry in the config file or as an environment variable exists.
      def override_value(definition)
        # The test setup should govern the configuration
        override_value_from_file(definition) unless Rails.env.test?
        override_value_from_env(definition)
      end

      def override_value_from_file(definition)
        name = definition.name

        ['default', Rails.env].each do |env|
          next unless file_config.dig(env, name)

          definition.override_value(file_config.dig(env, name))
        end
      end

      # Replace values for which an environment variable with the same key in upper case exists.
      # Also merges the existing values that are hashes with values from ENV if they follow the naming
      # schema.
      def override_value_from_env(definition)
        override_config_values(definition)
        merge_hash_config(definition) if definition.format == :hash
      end

      def override_config_values(definition)
        value = ENV[env_name(definition)]

        return unless value

        definition.override_value(extract_value(definition.name.upcase, value))
      end

      def merge_hash_config(definition)
        ENV.select { |k, _| k =~ /^#{env_name(definition)}/i }.each do |k, raw_value|
          _, value = path_to_hash(*path(ENV_PREFIX, k),
                                  extract_value(k, raw_value))
                        .first

          # There might be ENV vars that match the OPENPROJECT_ prefix but are no OP instance
          # settings, e.g. OPENPROJECT_DISABLE_DEV_ASSET_PROXY
          definition.override_value(value)
        end
      end

      def path(prefix, env_var_name)
        env_var_name
          .sub(/^#{prefix}/, '')
          .gsub(/([a-zA-Z0-9]|(__))+/)
          .map do |seg|
          unescape_underscores(seg.downcase)
        end
      end

      # takes the path provided and transforms it into a deeply nested hash
      # where the last parameter becomes the value.
      #
      # e.g. path_to_hash(:a, :b, :c, :d) => { a: { b: { c: :d } } }
      def path_to_hash(*path)
        value = path.pop

        path.reverse.inject(value) do |path_hash, key|
          { key => path_hash }
        end
      end

      def unescape_underscores(path_segment)
        path_segment.gsub '__', '_'
      end

      def env_name(definition)
        "#{ENV_PREFIX}#{definition.name.upcase.gsub('_', '__')}"
      end

      ##
      # Extract the configuration value from the given input
      # using YAML.
      #
      # @param key [String] The key of the input within the source hash.
      # @param original_value [String] The string from which to extract the actual value.
      # @return A ruby object (e.g. Integer, Float, String, Hash, Boolean, etc.)
      # @raise [ArgumentError] If the string could not be parsed.
      def extract_value(key, original_value)
        # YAML parses '' as false, but empty ENV variables will be passed as that.
        # To specify specific values, one can use !!str (-> '') or !!null (-> nil)
        return original_value if original_value == ''

        parsed = load_yaml(original_value)

        if parsed.is_a?(String)
          original_value
        else
          parsed
        end
      rescue StandardError => e
        raise ArgumentError, "Configuration value for '#{key}' is invalid: #{e.message}"
      end

      def load_yaml(source)
        YAML::safe_load(source, permitted_classes: [Symbol, Date])
      end

      attr_accessor :loaded
    end

    private

    attr_accessor :serialized,
                  :writable

    def deduce_format(value)
      case value
      when TrueClass, FalseClass
        :boolean
      when Integer, Date, DateTime, String, Hash, Array, Float, Symbol
        value.class.name.underscore.to_sym
      when ActiveSupport::Duration
        :duration
      else
        raise ArgumentError, "Cannot deduce the format for the setting definition #{name}"
      end
    end
  end
end
