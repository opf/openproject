#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
    AR_BOOLEAN_TYPE = ActiveRecord::Type::Boolean.new

    attr_accessor :name,
                  :format,
                  :env_alias

    attr_writer :value,
                :description,
                :allowed

    def initialize(name,
                   default:,
                   description: nil,
                   format: nil,
                   writable: true,
                   allowed: nil,
                   env_alias: nil)
      self.name = name.to_s
      @default = default.is_a?(Hash) ? default.deep_stringify_keys : default
      @default.freeze
      self.value = @default.dup
      self.format = format ? format.to_sym : deduce_format(value)
      self.writable = writable
      self.allowed = allowed
      self.env_alias = env_alias
      self.description = description.presence || :"setting_#{name}"
    end

    def default
      cast(@default)
    end

    def value
      cast(@value)
    end

    def description
      if @description.is_a?(Symbol)
        I18n.t(@description, default: nil)
      else
        @description
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

    def unprefixed_env_var_name_allowed?
      # Configuration values could be overridden with unprefixed env var
      # names before being harmonized (PR#10296). Using unprefixed en var
      # is deprecated and will be removed in 13.0.
      # Configuration are recognized by not being writable.
      !writable
    end

    def override_value(other_value)
      if format == :hash
        self.value = {} if value.nil?
        value.deep_merge! other_value.deep_stringify_keys
      elsif format == :datetime && !other_value.is_a?(DateTime)
        self.value = DateTime.parse(other_value.to_s)
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
      # @param [Object] default The default value the setting has if not overridden.
      # @param [nil] format The format the value is in e.g. symbol, array, hash, string. If a value is present,
      #  the format is deferred.
      # @param [nil] description A human-readable description of this setting.
      # @param [TrueClass] writable Whether the value can be set in the UI. In case the value is set via file or ENV var,
      #  this will be set to false later on and UI elements that refer to the definition will be disabled.
      # @param [nil] allowed The array of allowed values that can be assigned to the definition.
      #  Will serve to be validated against. A lambda can be provided returning an array in case
      #  the array needs to be evaluated dynamically. In case of e.g. boolean format, setting
      #  an allowed array is not necessary.
      # @param [nil] env_alias Alternative for the default env name to also look up. E.g. with the alias set to
      #  `OPENPROJECT_2FA` for a definition with the name `two_factor_authentication`, the value is fetched
      #  from the ENV OPENPROJECT_2FA as well.
      def add(name,
              default:,
              format: nil,
              description: nil,
              writable: true,
              allowed: nil,
              env_alias: nil)
        return if @by_name.present? && @by_name[name.to_s].present?

        @by_name = nil

        definition = new(name,
                         format:,
                         description:,
                         default:,
                         writable:,
                         allowed:,
                         env_alias:)

        override_value(definition)

        all << definition
      end

      def define(&)
        instance_exec(&)
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

      # Currently only required for testing.
      #
      # Tag your test with :settings_reset to start test with fresh settings
      # definitions and restore them after test.
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
        override_value_from_file(definition)
        override_value_from_env(definition)
      end

      def override_value_from_file(definition)
        envs = ['default', Rails.env]
        envs.delete('default') if Rails.env.test? # The test setup should govern the configuration
        envs.each do |env|
          next unless (env_config = file_config[env])
          next unless env_config.has_key?(definition.name)

          definition.override_value(env_config[definition.name])
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
        find_env_var_override(definition) do |env_var_name, env_var_value|
          value = extract_value_from_env(env_var_name, env_var_value)
          definition.override_value(value)
        end
      end

      def merge_hash_config(definition)
        merged_hash = {}
        each_env_var_hash_override(definition) do |env_var_name, env_var_value, env_var_hash_part|
          value = extract_hash_from_env(env_var_name, env_var_value, env_var_hash_part)
          merged_hash.deep_merge!(value)
        end
        return if merged_hash.empty?

        definition.override_value(merged_hash)
      end

      def extract_hash_from_env(env_var_name, env_var_value, env_var_hash_part)
        value = extract_value_from_env(env_var_name, env_var_value)
        path_to_hash(*hash_path(env_var_hash_part), value)
      end

      # takes the hash part of an env variable and turn it into a path.
      #
      # e.g. hash_path('KEY_SUB__KEY_SUB__SUB__KEY') => ['key', 'sub_key', 'sub_sub_key']
      def hash_path(env_var_hash_part)
        env_var_hash_part
          .scan(/(?:[a-zA-Z0-9]|__)+/)
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

      def find_env_var_override(definition)
        found_env_name = possible_env_names(definition).find { |name| ENV.key?(name) }
        return unless found_env_name

        if found_env_name == env_name_unprefixed(definition)
          Rails.logger.warn(
            "Using unprefixed environment variables is deprecated. " \
            "Please use #{env_name(definition)} instead of #{env_name_unprefixed(definition)}"
          )
        end
        yield found_env_name, ENV.fetch(found_env_name)
      end

      def each_env_var_hash_override(definition)
        hash_override_matcher =
          if definition.env_alias
            /^(?:#{env_name(definition)}|#{env_name_nested(definition)}|#{env_name_alias(definition)})_(.+)/i
          else
            /^(?:#{env_name(definition)}|#{env_name_nested(definition)})_(.+)/i
          end
        ENV.each do |env_var_name, env_var_value|
          env_var_name.match(hash_override_matcher) do |m|
            yield env_var_name, env_var_value, m[1]
          end
        end
      end

      def possible_env_names(definition)
        [
          env_name_nested(definition),
          env_name(definition),
          env_name_unprefixed(definition),
          env_name_alias(definition)
        ].compact
      end

      public :possible_env_names

      def env_name_nested(definition)
        "#{ENV_PREFIX}#{definition.name.upcase.gsub('_', '__')}"
      end

      def env_name(definition)
        "#{ENV_PREFIX}#{definition.name.upcase}"
      end

      def env_name_unprefixed(definition)
        definition.name.upcase if definition.unprefixed_env_var_name_allowed?
      end

      def env_name_alias(definition)
        return unless definition.env_alias

        definition.env_alias.upcase
      end

      ##
      # Extract the configuration value from the given environment variable
      # using YAML.
      #
      # @param env_var_name [String] The environment variable name.
      # @param env_var_value [String] The string from which to extract the actual value.
      # @return A ruby object (e.g. Integer, Float, String, Hash, Boolean, etc.)
      # @raise [ArgumentError] If the string could not be parsed.
      def extract_value_from_env(env_var_name, env_var_value)
        # YAML parses '' as false, but empty ENV variables will be passed as that.
        # To specify specific values, one can use !!str (-> '') or !!null (-> nil)
        return env_var_value if env_var_value == ''

        parsed = load_yaml(env_var_value)

        if parsed.is_a?(String)
          env_var_value
        else
          parsed
        end
      rescue StandardError => e
        raise ArgumentError, "Configuration value for environment variable '#{env_var_name}' is invalid: #{e.message}"
      end

      def load_yaml(source)
        YAML::safe_load(source, permitted_classes: [Symbol, Date])
      end

      attr_accessor :loaded
    end

    private

    attr_accessor :serialized,
                  :writable

    def cast(value)
      return nil if value.nil?

      value = value.call if value.respond_to?(:call)

      case format
      when :integer
        value.to_i
      when :float
        value.to_f
      when :boolean
        AR_BOOLEAN_TYPE.cast(value)
      when :symbol
        value.to_sym
      else
        value
      end
    end

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
