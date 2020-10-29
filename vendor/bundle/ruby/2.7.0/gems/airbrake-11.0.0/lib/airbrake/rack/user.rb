# frozen_string_literal: true

module Airbrake
  module Rack
    # Represents an authenticated user, which can be converted to Airbrake's
    # payload format. Supports Warden and Omniauth authentication frameworks.
    class User
      # Finds the user in the Rack environment and creates a new user wrapper.
      #
      # @param [Hash{String=>Object}] rack_env The Rack environment
      # @return [Airbrake::Rack::User, nil]
      def self.extract(rack_env)
        # Warden support (including Devise).
        if (warden = rack_env['warden'])
          user = warden.user(run_callbacks: false)
          # Early return to prevent unwanted possible authentication via
          # calling the `current_user` method later.
          # See: https://github.com/airbrake/airbrake/issues/641
          return user ? new(user) : nil
        end

        # Fallback mode (OmniAuth support included). Works only for Rails.
        user = try_current_user(rack_env)
        new(user) if user
      end

      def self.try_current_user(rack_env)
        controller = rack_env['action_controller.instance']
        return unless controller.respond_to?(:current_user, true)
        return unless [-1, 0].include?(controller.method(:current_user).arity)

        begin
          controller.__send__(:current_user)
        rescue Exception => _e # rubocop:disable Lint/RescueException
          nil
        end
      end
      private_class_method :try_current_user

      def initialize(user)
        @user = user
      end

      def as_json
        user = {}

        user[:id] = try_to_get(:id)
        user[:name] = full_name
        user[:username] = try_to_get(:username)
        user[:email] = try_to_get(:email)

        user = user.delete_if { |_key, val| val.nil? }
        user.empty? ? user : { user: user }
      end

      private

      def try_to_get(key)
        return unless @user.respond_to?(key)
        # try methods with no arguments or with variable number of arguments,
        # where none of them are required
        return unless @user.method(key).arity.between?(-1, 0)

        String(@user.__send__(key))
      end

      def full_name
        # Try to get first and last names. If that fails, try to get just 'name'.
        name = [try_to_get(:first_name), try_to_get(:last_name)].compact.join(' ')
        name.empty? ? try_to_get(:name) : name
      end
    end
  end
end
