module OpenProject::TwoFactorAuthentication
  module TokenStrategyManager
    class << self
      ##
      # Select a matching OTP strategy for the given user's default device.
      # It will select the first that supports the given channel
      def find_matching_strategy(channel)
        active_strategies.detect { |s| s.supported_channels.include? channel.to_sym }
      end

      # validate_configuration
      def validate_configuration!
        validate_active_strategies!
      end

      ##
      # Validate the configured set of strategies
      def validate_active_strategies!
        types = {}

        # Validate correctness of each strategy
        active_strategies.each do |strategy|
          strategy.validate!

          t = strategy.device_type
          if types.key? t
            raise ArgumentError, "Type #{t} already registered with strategy #{types[t].identifier}. " \
                                 "You cannot register two strategies with the same types."
          end

          types[t] = strategy
        end

        if enforced? && types.empty?
          raise ArgumentError, "2FA is set to enforced, but no active strategy exists"
        end
      end

      ##
      # Whether any active strategy exists
      def enabled?
        !active_strategies.empty?
      end

      ##
      # Determines whether admins can register devices on user's behalf
      def admin_register_sms_strategy
        enabled? && active_strategies.detect(&:mobile_token?)
      end

      ##
      # Whether the system requires 2FA for all users
      def enforced?
        !!configuration['enforced']
      end

      ##
      # Determine whether the plugin settings can be changed from the UI
      def configurable_by_ui?
        !configuration['hide_settings_menu_item']
      end

      def allow_remember_for_days
        configuration['allow_remember_for_days'].to_i
      end

      ##
      # Determine whether the given configuration is invalid
      def invalid_configuration?
        enforced? && !enabled?
      end

      ##
      # Fetch all active strategies
      def active_strategies
        configuration.fetch('active_strategies', [])
                     .map(&:to_s)
                     .uniq
                     .map { |strategy| lookup_active_strategy strategy }
      end

      ##
      # Get the unique strategy for the type
      def get_strategy(type)
        active_strategies.detect { |s| s.device_type == type }
      end

      ##
      # Get the available devices for the active strategies
      def available_devices
        types = Set.new
        active_strategies.each do |s|
          types << s.device_type
        end

        types.index_with { |type| ::TwoFactorAuthentication::Device.const_get(type.to_s.camelize) }
      end

      ##
      # 2FA Plugin configuration
      def configuration
        config = Setting.plugin_openproject_two_factor_authentication || {}

        merge_with_settings! config

        config
      end

      def enforced_by_configuration?
        enforced = (OpenProject::Configuration['2fa'] || {})['enforced']
        ActiveModel::Type::Boolean.new.cast enforced
      end

      def merge_with_settings!(config)
        config['active_strategies'] ||= []
        # Always enable webauthn and totp if nothing is enabled
        config['active_strategies'] += %i[totp webauthn] if add_default_strategy?(config)
      end

      def add_default_strategy?(config)
        config['active_strategies'].empty? && config['disabled'].blank?
      end

      def available_strategies
        {
          totp: I18n.t("activerecord.models.two_factor_authentication/device/totp"),
          webauthn: I18n.t("activerecord.models.two_factor_authentication/device/webauthn"),
          sns: I18n.t("activerecord.models.two_factor_authentication/device/sms"),
          message_bird: I18n.t("activerecord.models.two_factor_authentication/device/sms")
        }
      end

      def lookup_active_strategy(klazz)
        ::OpenProject::TwoFactorAuthentication::TokenStrategy.const_get klazz.to_s.camelize
      rescue NameError => e
        Rails.logger.error "Failed 2FA strategy lookup for #{klazz}: #{e}"
        raise ArgumentError, "Invalid 2FA strategy #{klazz}"
      end
    end
  end
end
