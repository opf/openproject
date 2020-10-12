require 'open_project/authentication/manager'

module OpenProject
  ##
  # OpenProject uses Warden strategies for request authentication.
  module Authentication
    class << self
      ##
      # Registers a given Warden strategy to be used for authentication.
      #
      # @param [Symbol] Name under which the strategy can be referred to.
      # @param [Class] The strategy class.
      # @param [String] The authentication scheme implemented by this strategy.
      #                 Used in the WWW-Authenticate header in 401 responses.
      def add_strategy(name, clazz, auth_scheme)
        Warden::Strategies.add name, clazz

        info = Manager.auth_scheme auth_scheme
        info.strategies << name
      end

      ##
      # Updates the used warden strategies for a given scope. The strategies will be tried
      # in the order they are set here. Plugins can call this to add or remove strategies.
      # For available scopes please refer to `OpenProject::Authentication::Scope`.
      #
      # @param [Symbol] scope The scope for which to update the used warden strategies.
      # @param [Hash] opts Options for that scope.
      # @option opts [Boolean] :store Indicates whether the user should be stored in the session
      #                               for this scope. Optional. If not given, the current store
      #                               flag for this strategy will remain unchanged what ever it is.
      # @option opts [String] :realm The WWW-Authenticate realm used for authentication challenges
      #                              for this scope. The default value ()
      #
      # @yield [strategies] A block returning the strategies to be used for this scope.
      # @yieldparam [Set] strategies The strategies currently used by this scope. May be empty.
      # @yieldreturn [Set] The strategies to be used by this scope.
      def update_strategies(scope, opts = {}, &block)
        raise ArgumentError, "invalid scope: #{scope}" unless Scope.values.include? scope

        config = Manager.scope_config scope
        config.update! opts, &block
      end

      ##
      # Allows to handle an authentication failure with a custom response.
      #
      # @param [Symbol] scope The scope for which to set the custom failure handler. Optional.
      #                       If omitted the default failure handler is set.
      #
      # @yield [failure_handler] A block returning a custom failure response.
      # @yieldparam [Warden::Proxy] warden Warden instance giving access to the would-be
      #                             result message and headers.
      # @yieldparam [Hash] warden_options Warden options including the scope of the failed
      #                                   strategy and the attempted request path.
      # @yieldreturn [Array] A rack standard response such as `[401, {}, ['unauthenticated']]`.
      def handle_failure(scope: nil, &block)
        Manager.failure_handlers[scope] = block
      end
    end

    ##
    # This module is only there to declare all used scopes. Technically a scope can be an
    # arbitrary symbol. But we declare them here not to lose sight of them.
    #
    # Plugins can declare new scopes by declaring new constants in this module.
    module Scope
      API_V3 = :api_v3

      class << self
        def values
          constants.map do |name|
            const_get name
          end
        end
      end
    end

    module Stage
      class Entry
        include OpenProject::StaticRouting::UrlHelpers

        attr_reader :identifier

        def initialize(identifier, path, run_after_activation, active)
          @identifier = identifier
          @path = path
          @run_after_activation = run_after_activation
          @active = active
        end

        def path
          if @path.respond_to?(:call)
            instance_exec &@path
          else
            @path
          end
        end

        def run_after_activation?
          @run_after_activation
        end

        def active?
          @active.call
        end
      end

      class << self
        include OpenProject::StaticRouting::UrlHelpers

        ##
        # Registers a new authentication stage which will be triggered after the
        # user has been authenticated through the core and before they are actually logged in.
        #
        # With a plugin registering an extra stage the login flow would look as follows:
        #
        #     :|--------------------|>-------------------|>----------------|:
        #           Password Auth      Extra Stage (2FA)    Complete Login
        #
        #      {       core         }{     2FA plugin    }{      core      }
        #
        # Only in the final complete login stage will the user's session be reset and
        # the current_user set to the successfully authenticated user. Until then the
        # initially authenticated user will be stored in the intermediate session
        # as `authenticated_user_id`.
        #
        # Any stage has to be completed by redirecting back to `Stage.complete_path`.
        # If the stage fails it may handle displaying the failure itself. If not it can
        # redirect to `Stage.failure_path` to show a generic failure page which will show
        # any flash errors.
        #
        # Example calls:
        #
        #     OpenProject::Authentication::Stage
        #       .register :security_question, '/users/security_question'
        #
        #     OpenProject::Authentication::Stage
        #       .register(:security_question) { security_question_path } # using url helper
        #
        # @param identifier [Symbol] Used to tell the stages apart.
        # @param path [String] Path to redirect to for the stage to start.
        # @param run_after_activation [Boolean] If true the stage will also be run just after
        #                                       a user was registered and activated. This only
        #                                       makes sense if the extra stage is possible at
        #                                       that point yet.
        # @param active [Block] A block returning true (default) if this stage is active.
        # @param before [Symbol] Identifier before which to insert this stage. Stage will be
        #                        appended to the end if no such identifier is registered.
        #                        Cannot be used with `after`.
        # @param after [Symbol] Identifier after which to insert this stage. The stage will be
        #                       appended to the end if no such identifier is registered.
        #                       Cannot be used with `before`.
        #
        # @yield [path_provider] A block returning a path to redirect to. Is evaluated in the
        #                        context of a controller giving access to URL helpers.
        def register(
          identifier,
          path = nil,
          run_after_activation: false,
          active: ->() { true },
          before: nil,
          after: nil,
          &block
        )
          if stages.detect { |s| s.identifier == identifier }
            Rails.logger.warn "Trying to register stage (#{identifier}) that exists already."
            return
          end

          stage = Entry.new identifier, path || block, run_after_activation, active
          i = stages.index { |s| s.identifier == (before || after) }

          if i
            stages.insert i + (after ? 1 : 0), stage
          else
            stages << stage
          end
        end

        def deregister(identifier)
          stages.reject! { |s| s.identifier == identifier }
        end

        ##
        # Contains 3-tuples of stage identifier, run-after-activation flag and
        # the block to be executed to start the stage.
        def stages
          @stages ||= []
        end

        def find_all(identifiers)
          identifiers
            .map { |ident| self.stages.find { |st| st.identifier == ident } }
            .compact
        end

        def complete_path(identifier, session:, back_url:nil)
          stage_success_path stage: identifier, secret: Hash(session[:stage_secrets])[identifier]
        end

        def failure_path(identifier)
          stage_failure_path stage: identifier
        end
      end
    end

    ##
    # Options used in the WWW-Authenticate header returned to the user
    # in case authentication failed (401).
    module WWWAuthenticate
      module_function

      def pick_auth_scheme(supported_schemes, default_scheme, request_headers = {})
        req_scheme = request_headers['HTTP_X_AUTHENTICATION_SCHEME']

        if supported_schemes.include? req_scheme
          req_scheme
        else
          default_scheme
        end
      end

      def default_auth_scheme
        'Basic'
      end

      def default_realm
        'OpenProject API'
      end

      def scope_realm(scope = nil)
        Manager.scope_config(scope).realm || default_realm
      end

      def response_header(
        default_auth_scheme: self.default_auth_scheme,
        scope: nil,
        request_headers: {}
      )
        scheme = pick_auth_scheme auth_schemes(scope), default_auth_scheme, request_headers

        "#{scheme} realm=\"#{scope_realm(scope)}\""
      end

      def auth_schemes(scope)
        strategies = Array(Manager.scope_config(scope).strategies)

        Manager.auth_schemes
          .select { |_, info| scope.nil? or not (info.strategies & strategies).empty? }
          .keys
      end
    end

    module AuthHeaders
      include WWWAuthenticate

      # #scope available from Warden::Strategies::BasicAuth

      def auth_scheme
        pick_auth_scheme auth_schemes(scope), default_auth_scheme, env
      end

      def realm
        scope_realm scope
      end
    end
  end
end

Warden::Strategies::BasicAuth.prepend OpenProject::Authentication::AuthHeaders
