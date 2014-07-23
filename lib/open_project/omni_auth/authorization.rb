module OpenProject
  module OmniAuth
    ##
    # Provides authorization mechanisms for OmniAuth-based authentication.
    module Authorization
      ##
      # Checks whether the given user is authorized to login by calling
      # all registered callbacks. If all callbacks approve the user is authorized and may log in.
      def self.authorized?(auth_hash)
        rejection = callbacks.find_map do |callback|
          d = callback.authorize auth_hash

          if d.is_a? Decision
            d if d.reject?
          else
            fail ArgumentError, 'Expecting Callback#authorize to return a Decision.'
          end
        end

        rejection || Approval.new
      end

      ##
      # Signals that the given user has been successfully authorized.
      #
      # Note: Only call if you know what you are doing.
      def self.authorized!(user)
        authorized_callbacks.each do |callback|
          callback.authorized user
        end
      end

      ##
      # Adds a callback to be executed before a user is logged in.
      # The given callback may reject the user to prevent authorization by
      # calling dec#reject(error) or approve by calling dec#approve.
      #
      # If not approved a user is implicitly rejected.
      #
      # @param opts [Hash] options for the callback registration
      # @option opts [Symbol] :provider Only call for given provider
      #
      # @yield [decision, user, auth_hash] Callback to be executed before the user is logged in.
      # @yieldparam [DecisionStore] dec object providing #approve and #reject
      # @yieldparam [User] user The OpenProject user to be logged in.
      # @yieldparam [AuthHash] OmniAuth authentication information including user info
      #                        and credentials.
      # @yieldreturn [Decision] A Decision indicating whether or not to authorize the user.
      def self.authorize_user(opts = {}, &block)
        if opts[:provider]
          authorize_user_for_provider opts[:provider], &block
        else
          add_authorize_user_callback AuthorizationBlockCallback.new(&block)
        end
      end

      def self.authorize_user_for_provider(provider, &block)
        callback = AuthorizationBlockCallback.new do |dec, auth_hash|
          if auth_hash.provider.to_sym == provider.to_sym
            block.call dec, auth_hash
          else
            dec.approve
          end
        end

        add_authorize_user_callback callback
      end

      ##
      # Registers a callback on the event of a successful user authorization.
      #
      # @yield [user] Callback called with the successfully authorized user.
      # @yieldparam user [User] User who has been authorized.
      def self.on_success(&block)
        add_authorized_callback AuthorizedBlockCallback.new(&block)
      end

      ##
      # Registers a new callback to decide whether or not a user is to be authorized.
      #
      # @param [AuthorizationCallback] Callback to be called upon user authorization.
      def self.add_authorize_user_callback(callback)
        callbacks << callback
      end

      def self.callbacks
        @callbacks ||= []
      end

      ##
      # Registers a new callback to successful user authorization.
      #
      # @param [AuthorizedCallback] Callback to be called upon successful authorization.
      def self.add_authorized_callback(callback)
        authorized_callbacks << callback
      end

      def self.authorized_callbacks
        @authorized_callbacks ||= []
      end

      ##
      # Performs user authorization.
      class AuthorizationCallback
        ##
        # Given an OmniAuth auth hash this decides if a user is authorized or not.
        #
        # @param [AuthHash] auth_hash OmniAuth authentication information including user info
        #                   and credentials.
        #
        # @return [Decision] A decision indicating whether the user is authorized or not.
        def authorize(auth_hash)
          fail "subclass responsibility: authorize(#{auth_hash})"
        end
      end

      ##
      # A callback triggering a given block.
      class AuthorizationBlockCallback < AuthorizationCallback
        attr_reader :block

        def initialize(&block)
          @block = block
        end

        def authorize(auth_hash)
          store = DecisionStore.new
          block.call store, auth_hash
          # failure to make a decision results in a rejection
          store.decision || Rejection.new(I18n.t('user.authorization_rejected'))
        end
      end

      ##
      # A callback for reacting to a user being authorized.
      class AuthorizedCallback
        ##
        # Is called after a user has been authorized successfully.
        #
        # @param [User] User who has been authorized.
        def authorized(user)
          fail "subclass responsibility: authorized(#{user})"
        end
      end

      ##
      # A authorized callback triggering a given block.
      class AuthorizedBlockCallback < AuthorizedCallback
        attr_reader :block

        def initialize(&block)
          @block = block
        end

        def authorized(user)
          block.call user
        end
      end

      ##
      # Abstract base class for an authorization decision.
      # Any subclass must either override #approve? or #reject?
      # the both of which are defined in terms of each other.
      class Decision
        def approve?
          !reject?
        end

        def reject?
          !approve?
        end

        def self.approve
          Approval.new
        end

        def self.reject(error_message)
          Rejection.new error_message
        end
      end

      ##
      # Indicates a rejected authorization attempt.
      class Rejection < Decision
        attr_reader :message

        def initialize(message)
          @message = message
        end

        def reject?
          true
        end
      end

      ##
      # Indicates an approved authorization.
      class Approval < Decision
        def approve?
          true
        end
      end

      ##
      # Stores a decision.
      class DecisionStore
        attr_accessor :decision

        def approve
          self.decision = Approval.new
        end

        def reject(error_message)
          self.decision = Rejection.new error_message
        end
      end

      Enumerable.class_eval do
        ##
        # Passes each element to the given block and returns the
        # result of the block as soon as it's truthy.
        def find_map(&block)
          each do |e|
            result = block.call e

            return result if result
          end

          nil
        end
      end
    end
  end
end
