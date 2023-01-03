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
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative 'configuration/helpers'
require_relative 'configuration/asset_host'

module OpenProject
  module Configuration
    extend Helpers

    TRUE_VALUES = ['true', true, '1'].freeze

    class << self
      # Returns a configuration setting
      def [](name)
        Settings::Definition[name]&.value
      end

      # Sets configuration setting
      def []=(name, value)
        Settings::Definition[name].value = value
      end

      def cache_store_configuration
        # rails defaults to :file_store, use :mem_cache_store when :memcache is configured in configuration.yml
        # Also use :mem_cache_store for when :dalli_store is configured
        cache_store = self['rails_cache_store'].try(:to_sym)

        case cache_store
        when :memcache, :dalli_store
          cache_config = [:mem_cache_store]
          cache_config << self['cache_memcache_server'] if self['cache_memcache_server']
          # default to :file_store
        when NilClass, :file_store
          cache_config = [:file_store, Rails.root.join('tmp/cache')]
        else
          cache_config = [cache_store]
        end

        parameters = cache_store_parameters
        cache_config << parameters unless parameters.empty?

        cache_config
      end

      def cache_store_parameters
        mapping = {
          'cache_expires_in_seconds' => %i[expires_in to_i],
          'cache_namespace' => %i[namespace to_s]
        }
        parameters = {}
        mapping.each_pair do |from, to|
          if self[from]
            to_key, method = to
            parameters[to_key] = self[from].method(method).call
          end
        end
        parameters
      end

      private

      def method_missing(name, *args, &)
        setting_name = name.to_s.sub(/\?$/, '')

        definition = Settings::Definition[setting_name]

        if definition
          define_config_methods(definition)

          send(name, *args, &)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        Settings::Definition.exists?(name.to_s.sub(/\?$/, '')) || super
      end

      def define_config_methods(definition)
        define_singleton_method definition.name do
          self[definition.name]
        end

        define_singleton_method "#{definition.name}?" do
          if definition.format != :boolean
            ActiveSupport::Deprecation.warn "Calling #{self}.#{definition.name}? is deprecated since it is not a boolean", caller
          end
          TRUE_VALUES.include? self[definition.name]
        end
      end

      # Filters a hash with String keys by a key prefix and removes the prefix from the keys
      def settings_of_prefix(prefix)
        Settings::Definition
          .all_of_prefix(prefix)
          .to_h { |setting| [setting.name.delete_prefix(prefix), setting.value] }
          .symbolize_keys!
      end
    end
  end
end
