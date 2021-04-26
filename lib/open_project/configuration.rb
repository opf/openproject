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

require_relative 'configuration/helpers'
require_relative 'configuration/asset_host'

module OpenProject
  module Configuration
    extend Helpers

    class << self
      # Returns a configuration setting
      def [](name)
        Settings::Definition[name]&.value
      end

      # Sets configuration setting
      def []=(name, value)
        Settings::Definition[name].value = value
      end

      def configure_cache(application_config)
        return unless override_cache_config? application_config

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

        parameters = cache_parameters
        cache_config << parameters if parameters.size > 0

        application_config.cache_store = cache_config
      end

      def override_cache_config?(application_config)
        # override if cache store is not set
        # or cache store is :file_store
        # or there is something to overwrite it
        application_config.cache_store.nil? ||
          application_config.cache_store == :file_store ||
          Settings::Definition['rails_cache_store'].present?
      end

      def migrate_mailer_configuration!
        # do not migrate if forced to legacy configuration (using settings or ENV)
        return true if @config['email_delivery_configuration'] == 'legacy'
        # do not migrate if no legacy configuration
        return true if @config['email_delivery_method'].blank?
        # do not migrate if the setting already exists and is not blank
        return true if Setting.email_delivery_method.present?

        Rails.logger.info 'Migrating existing email configuration to the settings table...'
        Setting.email_delivery_method = @config['email_delivery_method'].to_sym

        ['smtp_', 'sendmail_'].each do |config_type|
          mail_delivery_config = filter_hash_by_key_prefix(@config, config_type)

          unless mail_delivery_config.empty?
            mail_delivery_config.symbolize_keys! if mail_delivery_config.respond_to?(:symbolize_keys!)
            mail_delivery_config.each do |k, v|
              Setting["#{config_type}#{k}"] = case v
                                              when TrueClass
                                                1
                                              when FalseClass
                                                0
                                              else
                                                v
                                              end
            end
          end
        end
        true
      end

      def reload_mailer_configuration!
        if @config['email_delivery_configuration'] == 'legacy'
          configure_legacy_action_mailer(@config)
        else
          case Setting.email_delivery_method
          when :smtp
            ActionMailer::Base.perform_deliveries = true
            ActionMailer::Base.delivery_method = Setting.email_delivery_method

            reload_smtp_settings!
          when :sendmail
            ActionMailer::Base.perform_deliveries = true
            ActionMailer::Base.delivery_method = Setting.email_delivery_method
          end
        end
      rescue StandardError => e
        Rails.logger.warn "Unable to set ActionMailer settings (#{e.message}). " \
                          'Email sending will most likely NOT work.'
      end

      # This is used to configure email sending from users who prefer to
      # continue using environment variables of configuration.yml settings. Our
      # hosted SaaS version requires this.
      def configure_legacy_action_mailer(config)
        return true if config['email_delivery_method'].blank?

        ActionMailer::Base.perform_deliveries = true
        ActionMailer::Base.delivery_method = config['email_delivery_method'].to_sym

        ['smtp_', 'sendmail_'].each do |config_type|
          mail_delivery_config = filter_hash_by_key_prefix(config, config_type)

          unless mail_delivery_config.empty?
            mail_delivery_config.symbolize_keys! if mail_delivery_config.respond_to?(:symbolize_keys!)
            ActionMailer::Base.send("#{config_type + 'settings'}=", mail_delivery_config)
          end
        end
      end

      private

      def reload_smtp_settings!
        # Correct smtp settings when using authentication :none
        authentication = Setting.smtp_authentication.try(:to_sym)
        keys = %i[address port domain authentication user_name password]
        if authentication == :none
          # Rails Mailer will croak if passing :none as the authentication.
          # Instead, it requires to be removed from its settings
          ActionMailer::Base.smtp_settings.delete :user_name
          ActionMailer::Base.smtp_settings.delete :password
          ActionMailer::Base.smtp_settings.delete :authentication

          keys = %i[address port domain]
        end

        keys.each do |setting|
          value = Setting["smtp_#{setting}"]
          if value.present?
            ActionMailer::Base.smtp_settings[setting] = value
          else
            ActionMailer::Base.smtp_settings.delete setting
          end
        end

        ActionMailer::Base.smtp_settings[:enable_starttls_auto] = Setting.smtp_enable_starttls_auto?
        ActionMailer::Base.smtp_settings[:ssl] = Setting.smtp_ssl?
      end

      def cache_parameters
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

      # Filters a hash with String keys by a key prefix and removes the prefix from the keys
      def filter_hash_by_key_prefix(hash, prefix)
        filtered_hash = {}
        hash.each do |key, value|
          if key.start_with? prefix
            filtered_hash[key[prefix.length..-1]] = value
          end
        end
        filtered_hash
      end

      def method_missing(name, *args, &block)
        setting_name = name.to_s.sub('(=|\?)$', '')

        if Settings::Definition.exists?(setting_name)
          define_singleton_method setting_name do
            self[setting_name]
          end

          define_singleton_method "#setting_name}?" do
            ['true', true, '1'].include? self[setting_name]
          end
        end
      end

      def respond_to_missing?(name, include_private = false)
        Settings::Definition.exists?(name.to_ s.sub('(=|\?)$', '')) || super
      end

      def define_config_methods
        @config.each_key do |setting|
          next if respond_to? setting

          define_singleton_method setting do
            self[setting]
          end

          define_singleton_method "#{setting}?" do
            ['true', true, '1'].include? self[setting]
          end
        end
      end
    end
  end
end
