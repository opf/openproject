#-- encoding: UTF-8

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

    ENV_PREFIX ||= 'OPENPROJECT_'.freeze

    attr_accessor :name,
                  :format,
                  :value,
                  :api_name,
                  :serialized,
                  :api,
                  :admin,
                  :writable

    def initialize(name, format:, value:, api_name: name, serialized: false, api: true, admin: true, writable: true)
      self.name = name.to_s
      self.format = format.to_s
      self.value = value
      self.api_name = api_name
      self.serialized = serialized
      self.api = api
      self.admin = admin
      self.writable = writable
    end

    def serialized?
      !!serialized
    end

    def api?
      !!api
    end

    def admin?
      !!admin
    end

    def writable?
      !!writable
    end

    def merge_value(other_value)
      if format == 'hash'
        value.deep_merge! other_value
      else
        self.value = other_value
      end
    end

    class << self
      def add(name, value:, format: nil, api_name: name, serialized: false, api: true, admin: true, writable: true)
        return if @by_name.present? && @by_name[name.to_s].present?

        @by_name = nil

        all << new(name,
                   format: format,
                   value: value,
                   api_name: api_name,
                   serialized: serialized,
                   api: api,
                   admin: admin,
                   writable: writable)
      end

      def define(&block)
        instance_exec(&block)
      end

      def [](name)
        by_name ||= all.group_by(&:name).transform_values(&:first)

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

          override_config
        end

        @all
      end

      def add_key_value(key, value)
        format = case value
                 when TrueClass, FalseClass
                   :boolean
                 when Integer, Date, DateTime
                   value.class.name.downcase.to_sym
                 end

        add key,
            format: format,
            value: value,
            api: false,
            admin: true,
            serialized: value.is_a?(Hash) || value.is_a?(Array),
            writable: false
      end

      private

      # Currently only required for testing
      def reset
        @all = nil
        @loaded = false
        @by_name = nil
      end

      def by_name
        @by_name ||= all.group_by(&:name).transform_values(&:first)
      end

      def load_config_from_file
        filename = Rails.root.join('config/configuration.yml')

        if File.file?(filename)
          file_config = YAML::load(ERB.new(File.read(filename)).result)

          if file_config.is_a? Hash
            load_env_from_config(file_config, Rails.env)
          else
            warn "#{filename} is not a valid OpenProject configuration file, ignoring."
          end
        end
      end

      def load_env_from_config(config, env)
        config['default']&.each do |name, value|
          override_value(name, value)
        end
        config[env]&.each do |name, value|
          override_value(name, value  )
        end
      end

      # Replace config values for which an environment variable with the same key in upper case
      # exists.
      # Also merges the existing values that are hashes with values from ENV if they follow the naming
      # schema.
      def override_config(source = default_override_source)
        override_config_values(source)
        merge_hash_config(source)
      end

      def override_config_values(source)
        all
          .map(&:name)
          .select { |key| source.include? key.upcase }
          .each { |key| self[key] = extract_value key, source[key.upcase] }
      end

      def merge_hash_config(source, prefix: ENV_PREFIX)
        source.select { |k, _| k =~ /^#{prefix}/i }.each do |k, raw_value|
          name, value = path_to_hash(*path(prefix, k),
                                     extract_value(k, raw_value))
                          .first

          setting = self[name]
          # There might be ENV vars that match the OPENPROJECT_ prefix but are no OP instance
          # settings, e.g. OPENPROJECT_DISABLE_DEV_ASSET_PROXY
          next unless setting

          setting.merge_value(value)
          setting.writable = false
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

        parsed = YAML.load(original_value)

        if parsed.is_a?(String)
          original_value
        else
          parsed
        end
      rescue StandardError => e
        raise ArgumentError, "Configuration value for '#{key}' is invalid: #{e.message}"
      end

      ##
      # The default source for overriding configuration values
      # is ENV, but may be changed for testing purposes
      def default_override_source
        ENV
      end

      def override_value(name, value)
        if self[name]
          self[name].value = value
        else
          add_key_value(name, value)
        end
      end

      attr_accessor :loaded
    end
  end
end
