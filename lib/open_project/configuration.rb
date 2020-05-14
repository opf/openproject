#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

    ENV_PREFIX ||= 'OPENPROJECT_'.freeze

    # Configuration default values
    @defaults = {
      'edition'                 => 'standard',
      'attachments_storage'      => 'file',
      'attachments_storage_path' => nil,
      'attachments_grace_period' => 180,
      'autologin_cookie_name'   => 'autologin',
      'autologin_cookie_path'   => '/',
      'autologin_cookie_secure' => false,
      'database_cipher_key'     => nil,
      'show_community_links' => true,
      'log_level' => 'info',
      'scm_git_command'         => nil,
      'scm_subversion_command'  => nil,
      'scm_local_checkout_path' => 'repositories', # relative to OpenProject directory
      'disable_browser_cache'   => true,
      # default cache_store is :file_store in production and :memory_store in development
      'rails_cache_store'       => nil,
      'cache_expires_in_seconds' => nil,
      'cache_namespace' => nil,
      # use dalli defaults for memcache
      'cache_memcache_server'   => nil,
      # where to store session data
      'session_store'           => :cache_store,
      'session_cookie_name'     => '_open_project_session',
      # Destroy all sessions for current_user on logout
      'drop_old_sessions_on_logout' => true,
      # Destroy all sessions for current_user on login
      'drop_old_sessions_on_login' => false,
      # url-path prefix
      'rails_relative_url_root' => '',
      'rails_force_ssl' => false,
      'rails_asset_host' => nil,
      # Enable internal asset server
      'enable_internal_assets_server' => false,

      # Additional / overridden help links
      'force_help_link'         => nil,
      'force_formatting_help_link' => nil,

      # Impressum link to be set, nil by default (= hidden)
      'impressum_link' => nil,

      # user configuration
      'default_comment_sort_order' => 'asc',

      # email configuration
      'email_delivery_configuration' => 'inapp',
      'email_delivery_method' => nil,
      'smtp_address' => nil,
      'smtp_port' => nil,
      'smtp_domain' => nil, # HELO domain
      'smtp_authentication' => nil,
      'smtp_user_name' => nil,
      'smtp_password' => nil,
      'smtp_enable_starttls_auto' => nil,
      'smtp_openssl_verify_mode' => nil, # 'none', 'peer', 'client_once' or 'fail_if_no_peer_cert'
      'sendmail_location' => '/usr/sbin/sendmail',
      'sendmail_arguments' => '-i',

      'disable_password_login' => false,
      'auth_source_sso' => nil,
      'omniauth_direct_login_provider' => nil,
      'internal_password_confirmation' => true,

      'disable_password_choice' => false,
      'override_bcrypt_cost_factor' => nil,

      'disabled_modules' => [], # allow to disable default modules
      'hidden_menu_items' => {},
      'blacklisted_routes' => [],

      'apiv3_enable_basic_auth' => true,

      'onboarding_video_url' => 'https://player.vimeo.com/video/163426858?autoplay=1',
      'onboarding_enabled' => true,

      'youtube_channel' => 'https://www.youtube.com/c/OpenProjectCommunity',

      'ee_manager_visible' => true,

      # Health check configuration
      'health_checks_authentication_password' => nil,
      # Maximum number of backed up jobs (that are not yet executed)
      # before health check fails
      'health_checks_jobs_queue_count_threshold' => 50,
      # Maximum number of minutes that jobs have not yet run after their designated 'run_at' time
      'health_checks_jobs_never_ran_minutes_ago' => 5,

      'after_login_default_redirect_url' => nil,
      'after_first_login_redirect_url' => nil,

      'main_content_language' => 'english',

      # Allow in-context translations to be loaded with CSP
      'crowdin_in_context_translations' => true,

      'avatar_link_expiry_seconds' => 24.hours.to_i,

      # Default gravatar image, set to something other than 404
      # to ensure a default is returned
      'gravatar_fallback_image' => '404',

      'registration_footer' => {},

      # Display update / security badge, enabled by default
      'security_badge_displayed' => true,
      'installation_type' => "manual",
      'security_badge_url' => "https://releases.openproject.com/v1/check.svg",

      # Check for missing migrations in internal errors
      'migration_check_on_exceptions' => true,

      # Show pending migrations as warning bar
      'show_pending_migrations_warning' => true,

      # Show mismatched protocol/hostname warning
      # in settings where they must differ this can be disabled
      'show_setting_mismatch_warning' => true,

      # Render warning bars (pending migrations, deprecation, unsupported browsers)
      # Set to false to globally disable this for all users!
      'show_warning_bars' => true,

      # Render storage information
      'show_storage_information' => true,

      # Log errors to sentry instance
      'sentry_dsn' => nil,
      # Allow separate error reporting for frontend errors
      'sentry_frontend_dsn' => nil,
      'sentry_host' => 'https://sentry.openproject.com',

      # Allow connection to Augur
      'enterprise_trial_creation_host' => 'https://augur.openproject.com',

      # Allow override of LDAP options
      'ldap_auth_source_tls_options' => nil
    }

    @config = nil

    class << self
      # Loads the OpenProject configuration file
      # Valid options:
      # * <tt>:file</tt>: the configuration file to load (default: config/configuration.yml)
      # * <tt>:env</tt>: the environment to load the configuration for (default: Rails.env)
      def load(options = {})
        filename = options[:file] || File.join(Rails.root, 'config', 'configuration.yml')
        env = options[:env] || Rails.env

        @config = @defaults.dup

        load_config_from_file(filename, env, @config)

        convert_old_email_settings(@config)

        override_config!(@config)

        define_config_methods

        @config = @config.with_indifferent_access
      end

      # Replace config values for which an environment variable with the same key in upper case
      # exists
      def override_config!(config, source = default_override_source)
        config.keys.select { |key| source.include? key.upcase }
              .each   { |key| config[key] = extract_value key, source[key.upcase] }

        config.deep_merge! merge_config(config, source)
      end

      def merge_config(config, source, prefix: ENV_PREFIX)
        new_config = config.dup.with_indifferent_access

        source.select { |k, _| k =~ /^#{prefix}/i }.each do |k, value|
          path = self.path prefix, k

          path_config = path_to_hash(*path, extract_value(k, value))

          new_config.deep_merge! path_config
        end

        new_config
      end

      def path(prefix, env_var_name)
        path = []
        env_var_name = env_var_name.sub /^#{prefix}/, ''

        env_var_name.gsub(/([a-zA-Z0-9]|(__))+/) do |seg|
          path << unescape_underscores(seg.downcase).to_sym
        end

        path
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

      def get_value(value)
        value
      end

      def unescape_underscores(path_segment)
        path_segment.gsub '__', '_'
      end

      # Returns a configuration setting
      def [](name)
        load unless @config
        @config[name]
      end

      # Sets configuration setting
      def []=(name, value)
        load unless @config
        @config[name] = value
      end

      # Yields a block with the specified hash configuration settings
      def with(settings)
        settings.stringify_keys!
        load unless @config
        was = settings.keys.inject({}) { |h, v| h[v] = @config[v]; h }
        @config.merge! settings
        yield if block_given?
        @config.merge! was
      end

      def configure_cache(application_config)
        return unless override_cache_config? application_config

        # rails defaults to :file_store, use :dalli when :memcaches is configured in configuration.yml
        cache_store = @config['rails_cache_store'].try(:to_sym)
        if cache_store == :memcache
          cache_config = [:dalli_store]
          cache_config << @config['cache_memcache_server'] \
            if @config['cache_memcache_server']
        # default to :file_store
        elsif cache_store.nil? || cache_store == :file_store
          cache_config = [:file_store, Rails.root.join('tmp/cache')]
        else
          cache_config = [cache_store]
        end
        parameters = cache_parameters(@config)
        cache_config << parameters if parameters.size > 0
        application_config.cache_store = cache_config
      end

      def override_cache_config?(application_config)
        # override if cache store is not set
        # or cache store is :file_store
        # or there is something to overwrite it
        application_config.cache_store.nil? ||
          application_config.cache_store == :file_store ||
          @config['rails_cache_store'].present?
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

      ##
      # The default source for overriding configuration values
      # is ENV, but may be changed for testing purposes
      def default_override_source
        ENV
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

      def load_config_from_file(filename, env, config)
        if File.file?(filename)
          file_config = YAML::load(ERB.new(File.read(filename)).result)
          if file_config.is_a? Hash
            config.merge!(load_env_from_config(file_config, env))
          else
            warn "#{filename} is not a valid OpenProject configuration file, ignoring."
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

      # Convert old mail settings
      #
      # SMTP Example:
      # mail_delivery.smtp_settings.<key> is converted to smtp_<key>
      # options:
      # disable_deprecation_message - used by testing
      def convert_old_email_settings(config, options = {})
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

      def cache_parameters(config)
        mapping = {
          'cache_expires_in_seconds' => [:expires_in, :to_i],
          'cache_namespace' => [:namespace, :to_s]
        }
        parameters = {}
        mapping.each_pair do |from, to|
          if config[from]
            to_key, method = to
            parameters[to_key] = config[from].method(method).call
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

      def define_config_methods
        @config.keys.each do |setting|
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
