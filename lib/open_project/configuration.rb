#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Configuration

    # Configuration default values
    @defaults = {
      'attachments_storage_path' => nil,
      'autologin_cookie_name'   => 'autologin',
      'autologin_cookie_path'   => '/',
      'autologin_cookie_secure' => false,
      'database_cipher_key'     => nil,
      'scm_git_command'         => nil,
      'scm_subversion_command'  => nil,

      # email configuration
      'email_delivery_method' => nil,
      'smtp_address' => nil,
      'smtp_port' => nil,
      'smtp_domain' => nil,  # HELO domain
      'smtp_authentication' => nil,
      'smtp_user_name' => nil,
      'smtp_password' => nil,
      'smtp_enable_starttls_auto' => nil,
      'smtp_openssl_verify_mode' => nil,  # 'none', 'peer', 'client_once' or 'fail_if_no_peer_cert'
      'sendmail_location' => nil,
      'sendmail_arguments' => nil
    }

    @config = nil

    class << self
      # Loads the Redmine configuration file
      # Valid options:
      # * <tt>:file</tt>: the configuration file to load (default: config/configuration.yml)
      # * <tt>:env</tt>: the environment to load the configuration for (default: Rails.env)
      def load(options={})
        filename = options[:file] || File.join(Rails.root, 'config', 'configuration.yml')
        env = options[:env] || Rails.env

        @config = @defaults.dup

        load_config_from_file(filename, env, @config)

        convert_old_email_settings(@config)

        load_overrides_from_environment_variables(@config)

        if @config['email_delivery_method']
          configure_action_mailer(@config)
        end

        @config
      end

      # Replace config values for which an environment variable with the same key in upper case
      # exists
      def load_overrides_from_environment_variables(config)
        config.each do |key, value|
          config[key] = ENV.fetch(key.upcase, value)
        end
      end

      # Returns a configuration setting
      def [](name)
        load unless @config
        @config[name]
      end

      # Yields a block with the specified hash configuration settings
      def with(settings)
        settings.stringify_keys!
        load unless @config
        was = settings.keys.inject({}) {|h,v| h[v] = @config[v]; h}
        @config.merge! settings
        yield if block_given?
        @config.merge! was
      end

      private

      def load_config_from_file(filename, env, config)
        if File.file?(filename)
          file_config = YAML::load_file(filename)
          unless file_config.kind_of? Hash
            warn "#{filename} is not a valid OpenProject configuration file, ignoring."
          else
            config.merge!(load_env_from_config(file_config, env))
          end
        end
      end

      def load_env_from_config(config, env)
        merged_config = {}

        if config['default']
          merged_config.merge!(config['default'])
        end
        if config[env]
          merged_config.merge!(config[env])
        end
        merged_config
      end

      def configure_action_mailer(config)
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

      # Convert old mail settings
      #
      # SMTP Example:
      # mail_delivery.smtp_settings.<key> is converted to smtp_<key>
      # options:
      # disable_deprecation_message - used by testing
      def convert_old_email_settings(config, options={})
        if config['email_delivery']
          unless options[:disable_deprecation_message]
            ActiveSupport::Deprecation.warn 'Deprecated mail delivery settings used. Please ' +
                                            'update them in config/configuration.yml or use ' +
                                            'environment variables. See doc/CONFIGURATION.md for ' +
                                            'more information.'
          end

          config['email_delivery_method'] = config['email_delivery']['delivery_method'] || :smtp

          ['sendmail', 'smtp'].each do |settings_type|
            settings_key = "#{settings_type}_settings"
            if config['email_delivery'][settings_key]
              config['email_delivery'][settings_key].each do |key, value|
                config["#{settings_type}_#{key}"] = value
              end
            end
          end
          config.delete('email_delivery')
        end
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

    end
  end
end
