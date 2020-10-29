# frozen_string_literal: true

module Airbrake
  module Rails
    # App is a wrapper around Rails.application.
    #
    # @since v9.0.3
    # @api private
    class App
      Route = Struct.new(:path)

      # @param [] request
      # @return [Airbrake::Rails::App::Route, nil]
      # rubocop:disable Metrics/AbcSize
      def self.recognize_route(request)
        # Duplicate `request` because `recognize` *can* strip the request's
        # `path_info`, which results in broken engine links (when the engine has
        # an isolated namespace).
        request_copy = request.dup

        # Save original script name because `router.recognize(request)` mutates
        # it. It's a Rails bug. More info in:
        #   * https://github.com/airbrake/airbrake/issues/1072
        #   * https://github.com/rails/rails/issues/31152
        original_script_name = request.env['SCRIPT_NAME']

        # We must search every engine individually to find a concrete route. If
        # we rely only on the `Rails.application.routes.router`, then the
        # recognize call would return the root route, neglecting PATH_INFO
        # completely. For example:
        #   * a request is made to `marketing#pricing`
        #   * `Rails.application` recognizes it as `marketing#/` (incorrect)
        #   * `Marketing::Engine` recognizes it as `marketing#/pricing` (correct)
        engines.each do |engine|
          engine.routes.router.recognize(request_copy) do |route, _params|
            # Restore original script name. Remove this code when/if the Rails
            # bug is fixed: https://github.com/airbrake/airbrake/issues/1072
            request.env['SCRIPT_NAME'] = original_script_name

            # Skip "catch-all" routes such as:
            #   get '*path => 'pages#about'
            #
            # @todo The `glob?` method was added in Rails v4.2.0.beta1. We
            # should remove the `respond_to?` check once we drop old Rails
            # versions support.
            #
            # https://github.com/rails/rails/commit/5460591f0226a9d248b7b4f89186bd5553e7768f
            next if route.respond_to?(:glob?) && route.glob?

            path =
              if engine == ::Rails.application
                route.path.spec.to_s
              else
                "#{engine.engine_name}##{route.path.spec}"
              end

            # Rails can recognize multiple routes for the given request. For
            # example, if we visit /users/2/edit, then Rails sees these routes:
            #   * "/users/:id/edit(.:format)"
            #   *  "/"
            #
            # We return the first route as, what it seems, the most optimal
            # approach.
            return Route.new(path)
          end
        end

        nil
      end
      # rubocop:enable Metrics/AbcSize

      def self.engines
        @engines ||= [*::Rails::Engine.subclasses, ::Rails.application]
      end
      private_class_method :engines
    end
  end
end
