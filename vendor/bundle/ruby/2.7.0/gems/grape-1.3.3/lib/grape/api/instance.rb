# frozen_string_literal: true

require 'grape/router'

module Grape
  class API
    # The API Instance class, is the engine behind Grape::API. Each class that inherits
    # from this will represent a different API instance
    class Instance
      include Grape::DSL::API

      class << self
        attr_reader :instance
        attr_reader :base
        attr_accessor :configuration

        def given(conditional_option, &block)
          evaluate_as_instance_with_configuration(block, lazy: true) if conditional_option && block_given?
        end

        def mounted(&block)
          evaluate_as_instance_with_configuration(block, lazy: true)
        end

        def base=(grape_api)
          @base = grape_api
          grape_api.instances << self
        end

        def to_s
          (base && base.to_s) || super
        end

        def base_instance?
          self == base.base_instance
        end

        # A class-level lock to ensure the API is not compiled by multiple
        # threads simultaneously within the same process.
        LOCK = Mutex.new

        # Clears all defined routes, endpoints, etc., on this API.
        def reset!
          reset_endpoints!
          reset_routes!
          reset_validations!
        end

        # Parses the API's definition and compiles it into an instance of
        # Grape::API.
        def compile
          @instance ||= new
        end

        # Wipe the compiled API so we can recompile after changes were made.
        def change!
          @instance = nil
        end

        # This is the interface point between Rack and Grape; it accepts a request
        # from Rack and ultimately returns an array of three values: the status,
        # the headers, and the body. See [the rack specification]
        # (http://www.rubydoc.info/github/rack/rack/master/file/SPEC) for more.
        def call(env)
          compile!
          call!(env)
        end

        # A non-synchronized version of ::call.
        def call!(env)
          instance.call(env)
        end

        # (see #cascade?)
        def cascade(value = nil)
          if value.nil?
            inheritable_setting.namespace_inheritable.key?(:cascade) ? !namespace_inheritable(:cascade).nil? : true
          else
            namespace_inheritable(:cascade, value)
          end
        end

        def compile!
          return if instance
          LOCK.synchronize { compile unless instance }
        end

        # see Grape::Router#recognize_path
        def recognize_path(path)
          compile!
          instance.router.recognize_path(path)
        end

        protected

        def prepare_routes
          endpoints.map(&:routes).flatten
        end

        # Execute first the provided block, then each of the
        # block passed in. Allows for simple 'before' setups
        # of settings stack pushes.
        def nest(*blocks, &block)
          blocks.reject!(&:nil?)
          if blocks.any?
            evaluate_as_instance_with_configuration(block) if block_given?
            blocks.each { |b| evaluate_as_instance_with_configuration(b) }
            reset_validations!
          else
            instance_eval(&block)
          end
        end

        def evaluate_as_instance_with_configuration(block, lazy: false)
          lazy_block = Grape::Util::LazyBlock.new do |configuration|
            value_for_configuration = configuration
            if value_for_configuration.respond_to?(:lazy?) && value_for_configuration.lazy?
              self.configuration = value_for_configuration.evaluate
            end
            response = instance_eval(&block)
            self.configuration = value_for_configuration
            response
          end
          if base && base_instance? && lazy
            lazy_block
          else
            lazy_block.evaluate_from(configuration)
          end
        end

        def inherited(subclass)
          subclass.reset!
          subclass.logger = logger.clone
        end

        def inherit_settings(other_settings)
          top_level_setting.inherit_from other_settings.point_in_time_copy

          # Propagate any inherited params down to our endpoints, and reset any
          # compiled routes.
          endpoints.each do |e|
            e.inherit_settings(top_level_setting.namespace_stackable)
            e.reset_routes!
          end

          reset_routes!
        end
      end

      attr_reader :router

      # Builds the routes from the defined endpoints, effectively compiling
      # this API into a usable form.
      def initialize
        @router = Router.new
        add_head_not_allowed_methods_and_options_methods
        self.class.endpoints.each do |endpoint|
          endpoint.mount_in(@router)
        end

        @router.compile!
        @router.freeze
      end

      # Handle a request. See Rack documentation for what `env` is.
      def call(env)
        result = @router.call(env)
        result[1].delete(Grape::Http::Headers::X_CASCADE) unless cascade?
        result
      end

      # Some requests may return a HTTP 404 error if grape cannot find a matching
      # route. In this case, Grape::Router adds a X-Cascade header to the response
      # and sets it to 'pass', indicating to grape's parents they should keep
      # looking for a matching route on other resources.
      #
      # In some applications (e.g. mounting grape on rails), one might need to trap
      # errors from reaching upstream. This is effectivelly done by unsetting
      # X-Cascade. Default :cascade is true.
      def cascade?
        return self.class.namespace_inheritable(:cascade) if self.class.inheritable_setting.namespace_inheritable.key?(:cascade)
        return self.class.namespace_inheritable(:version_options)[:cascade] if self.class.namespace_inheritable(:version_options) && self.class.namespace_inheritable(:version_options).key?(:cascade)
        true
      end

      reset!

      private

      # For every resource add a 'OPTIONS' route that returns an HTTP 204 response
      # with a list of HTTP methods that can be called. Also add a route that
      # will return an HTTP 405 response for any HTTP method that the resource
      # cannot handle.
      def add_head_not_allowed_methods_and_options_methods
        routes_map = {}

        self.class.endpoints.each do |endpoint|
          routes = endpoint.routes
          routes.each do |route|
            # using the :any shorthand produces [nil] for route methods, substitute all manually
            route_key = route.pattern.to_regexp
            routes_map[route_key] ||= {}
            route_settings = routes_map[route_key]
            route_settings[:pattern] = route.pattern
            route_settings[:requirements] = route.requirements
            route_settings[:path] = route.origin
            route_settings[:methods] ||= []
            if route.request_method == '*' || route_settings[:methods].include?('*')
              route_settings[:methods] = Grape::Http::Headers::SUPPORTED_METHODS
            else
              route_settings[:methods] << route.request_method
            end
            route_settings[:endpoint] = route.app
          end
        end

        # The paths we collected are prepared (cf. Path#prepare), so they
        # contain already versioning information when using path versioning.
        # Disable versioning so adding a route won't prepend versioning
        # informations again.
        without_root_prefix do
          without_versioning do
            routes_map.each_value do |config|
              methods = config[:methods]
              allowed_methods = methods.dup

              unless self.class.namespace_inheritable(:do_not_route_head)
                allowed_methods |= [Grape::Http::Headers::HEAD] if allowed_methods.include?(Grape::Http::Headers::GET)
              end

              allow_header = (self.class.namespace_inheritable(:do_not_route_options) ? allowed_methods : [Grape::Http::Headers::OPTIONS] | allowed_methods)

              unless self.class.namespace_inheritable(:do_not_route_options) || allowed_methods.include?(Grape::Http::Headers::OPTIONS)
                config[:endpoint].options[:options_route_enabled] = true
              end

              attributes = config.merge(allowed_methods: allowed_methods, allow_header: allow_header)
              generate_not_allowed_method(config[:pattern], **attributes)
            end
          end
        end
      end

      # Generate a route that returns an HTTP 405 response for a user defined
      # path on methods not specified
      def generate_not_allowed_method(pattern, allowed_methods: [], **attributes)
        supported_methods =
          if self.class.namespace_inheritable(:do_not_route_options)
            Grape::Http::Headers::SUPPORTED_METHODS
          else
            Grape::Http::Headers::SUPPORTED_METHODS_WITHOUT_OPTIONS
          end
        not_allowed_methods = supported_methods - allowed_methods
        return if not_allowed_methods.empty?

        @router.associate_routes(pattern, not_allowed_methods: not_allowed_methods, **attributes)
      end

      # Allows definition of endpoints that ignore the versioning configuration
      # used by the rest of your API.
      def without_versioning(&_block)
        old_version = self.class.namespace_inheritable(:version)
        old_version_options = self.class.namespace_inheritable(:version_options)

        self.class.namespace_inheritable_to_nil(:version)
        self.class.namespace_inheritable_to_nil(:version_options)

        yield

        self.class.namespace_inheritable(:version, old_version)
        self.class.namespace_inheritable(:version_options, old_version_options)
      end

      # Allows definition of endpoints that ignore the root prefix used by the
      # rest of your API.
      def without_root_prefix(&_block)
        old_prefix = self.class.namespace_inheritable(:root_prefix)

        self.class.namespace_inheritable_to_nil(:root_prefix)

        yield

        self.class.namespace_inheritable(:root_prefix, old_prefix)
      end
    end
  end
end
