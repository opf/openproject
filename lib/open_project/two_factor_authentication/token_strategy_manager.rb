module OpenProject::TwoFactorAuthentication
  module TokenStrategyManager
    class << self
      ##
      # Select a matching OTP strategy for the given user's default device.
      # It will select the first that supports the given channel
      def find_matching_strategy(channel)
        active_strategies.detect { |s| s.supported_channels.include? channel.to_sym }
      end

      #validate_configuration
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
        !active_strategies.empty? && EnterpriseToken.allows_to?(:two_factor_authentication)
      end

      ##
      # Determines whether admins can register devices on user's behalf
      def admin_register_sms_strategy
        enabled? && active_strategies.detect { |strategy_class| strategy_class.mobile_token? }
      end

      ##
      # Whether the system requires 2FA for all users
      def enforced?
        !!configuration[:enforced]
      end

      def allow_remember_for_days
        configuration[:allow_remember_for_days].to_i
      end

      ##
      # Determine whether the given configuration is invalid
      def invalid_configuration?
        enforced? && !enabled?
      end

      ##
      # Fetch all active strategies
      def active_strategies
        configuration.fetch(:active_strategies, [])
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

        classes = types.map { |type| [type, ::TwoFactorAuthentication::Device.const_get(type.to_s.camelize)] }
        Hash[classes]
      end

      ##
      # 2FA Plugin configuration
      def configuration
        config = OpenProject::Configuration['2fa'] || {}
        settings = Setting.plugin_openproject_two_factor_authentication || {}

        merge_with_settings! config, settings

        config
      end

      def merge_with_settings!(config, settings)
        # Allow enforcing from settings if not true in configuration
        unless config[:enforced]
          config[:enforced] = settings[:enforced]
        end

        predefined_strategies = config.fetch(:active_strategies, [])
        additional_strategies = settings.fetch(:active_strategies, [])

        config[:active_strategies] = predefined_strategies | additional_strategies
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