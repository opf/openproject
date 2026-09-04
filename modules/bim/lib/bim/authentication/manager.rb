# frozen_string_literal: true

module Bim
  module Authentication
    # Manages authentication adapters and orchestrates authentication flow
    class Manager
      class << self
        # Get all registered and enabled adapters
        # @return [Array<Adapter>]
        def adapters
          @adapters ||= load_adapters.select(&:enabled?).sort_by(&:priority)
        end

        # Authenticate using all enabled adapters in priority order
        # @param credentials [Hash] Authentication credentials
        # @return [User, nil] Authenticated user or nil
        def authenticate(credentials)
          adapters.each do |adapter|
            Rails.logger.debug "Trying authentication adapter: #{adapter.name}"

            begin
              user = adapter.authenticate(credentials)
              if user
                Rails.logger.info "User authenticated via #{adapter.name}: #{user.login}"
                return user
              end
            rescue StandardError => e
              Rails.logger.error "Authentication adapter #{adapter.name} failed: #{e.message}"
            end
          end

          Rails.logger.warn "Authentication failed for all adapters"
          nil
        end

        # Register a custom adapter
        # @param adapter_class [Class] Adapter class inheriting from Bim::Authentication::Adapter
        def register_adapter(adapter_class)
          unless adapter_class < Adapter
            raise ArgumentError, "Adapter must inherit from Bim::Authentication::Adapter"
          end

          custom_adapters << adapter_class
          @adapters = nil # Reset cached adapters
        end

        # Get list of adapters that support 2FA
        # @return [Array<Adapter>]
        def two_factor_adapters
          adapters.select(&:supports_2fa?)
        end

        # Check if 2FA is available
        # @return [Boolean]
        def two_factor_available?
          two_factor_adapters.any?
        end

        private

        def load_adapters
          adapters = []

          # Built-in adapters
          adapters << DatabaseAdapter.new
          adapters << ApiTokenAdapter.new

          # Optional adapters (only if enabled)
          adapters << SsoAdapter.new if SsoAdapter.available?
          adapters << LdapAdapter.new if LdapAdapter.available?
          adapters << TwoFactorAdapter.new if TwoFactorAdapter.available?

          # Custom registered adapters
          adapters.concat(custom_adapters.map(&:new))

          adapters
        end

        def custom_adapters
          @custom_adapters ||= []
        end
      end
    end
  end
end
