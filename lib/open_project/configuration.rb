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
          self['rails_cache_store'].present?
      end

      def migrate_mailer_configuration!
        # do not migrate if forced to legacy configuration (using settings or ENV)
        return true if self['email_delivery_configuration'] == 'legacy'
        # do not migrate if no legacy configuration
        return true if self['email_delivery_method'].blank?
        # do not migrate if the setting already exists and is not blank
        return true if Setting.email_delivery_method.present?

        Rails.logger.info 'Migrating existing email configuration to the settings table...'
        Setting.email_delivery_method = self['email_delivery_method'].to_sym

        ['smtp_', 'sendmail_'].each do |config_type|
          mail_delivery_configs = Settings::Definition.all_of_prefix(config_type)

          next if mail_delivery_configs.empty?

          mail_delivery_configs.each do |config|
            Setting["#{config_type}#{config.name}"] = case config.value
                                                      when TrueClass
                                                        1
                                                      when FalseClass
                                                        0
                                                      else
                                                        v
                                                      end
          end
        end

        true
      end

      def reload_mailer_configuration!
        if self['email_delivery_configuration'] == 'legacy'
          configure_legacy_action_mailer
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
      def configure_legacy_action_mailer
        return true if self['email_delivery_method'].blank?

        ActionMailer::Base.perform_deliveries = true
        ActionMailer::Base.delivery_method = self['email_delivery_method'].to_sym

        ['smtp_', 'sendmail_'].each do |config_type|
          config = settings_of_prefix(config_type)

          next if config.empty?

          ActionMailer::Base.send("#{config_type + 'settings'}=", config)
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

      def method_missing(name, *args, &block)
        setting_name = name.to_s.sub(/(=|\?)$/, '')

        if Settings::Definition.exists?(setting_name)
          define_config_methods(setting_name)

          send(setting_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, include_private = false)
        Settings::Definition.exists?(name.to_s.sub(/(=|\?)$/, '')) || super
      end

      def define_config_methods(setting_name)
        define_singleton_method setting_name do
          self[setting_name]
        end

        define_singleton_method "#{setting_name}?" do
          ['true', true, '1'].include? self[setting_name]
        end
      end


      # Filters a hash with String keys by a key prefix and removes the prefix from the keys
      def settings_of_prefix(prefix)
        Settings::Definition
          .all_of_prefix(prefix)
          .map { |setting| [setting.name.delete_prefix(prefix), setting.value] }
          .to_h
          .symbolize_keys!
      end
    end
  end
end
