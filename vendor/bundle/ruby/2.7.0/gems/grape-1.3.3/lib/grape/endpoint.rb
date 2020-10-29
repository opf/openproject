# frozen_string_literal: true

module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc.
  class Endpoint
    include Grape::DSL::Settings
    include Grape::DSL::InsideRoute

    attr_accessor :block, :source, :options
    attr_reader :env, :request, :headers, :params

    class << self
      def new(*args, &block)
        self == Endpoint ? Class.new(Endpoint).new(*args, &block) : super
      end

      def before_each(new_setup = false, &block)
        @before_each ||= []
        if new_setup == false
          return @before_each unless block_given?
          @before_each << block
        else
          @before_each = [new_setup]
        end
      end

      def run_before_each(endpoint)
        superclass.run_before_each(endpoint) unless self == Endpoint
        before_each.each { |blk| blk.call(endpoint) if blk.respond_to?(:call) }
      end

      # @api private
      #
      # Create an UnboundMethod that is appropriate for executing an endpoint
      # route.
      #
      # The unbound method allows explicit calls to +return+ without raising a
      # +LocalJumpError+. The method will be removed, but a +Proc+ reference to
      # it will be returned. The returned +Proc+ expects a single argument: the
      # instance of +Endpoint+ to bind to the method during the call.
      #
      # @param [String, Symbol] method_name
      # @return [Proc]
      # @raise [NameError] an instance method with the same name already exists
      def generate_api_method(method_name, &block)
        if method_defined?(method_name)
          raise NameError.new("method #{method_name.inspect} already exists and cannot be used as an unbound method name")
        end

        define_method(method_name, &block)
        method = instance_method(method_name)
        remove_method(method_name)

        proc do |endpoint_instance|
          ActiveSupport::Notifications.instrument('endpoint_render.grape', endpoint: endpoint_instance) do
            method.bind(endpoint_instance).call
          end
        end
      end
    end

    # Create a new endpoint.
    # @param new_settings [InheritableSetting] settings to determine the params,
    #   validations, and other properties from.
    # @param options [Hash] attributes of this endpoint
    # @option options path [String or Array] the path to this endpoint, within
    #   the current scope.
    # @option options method [String or Array] which HTTP method(s) can be used
    #   to reach this endpoint.
    # @option options route_options [Hash]
    # @note This happens at the time of API definition, so in this context the
    # endpoint does not know if it will be mounted under a different endpoint.
    # @yield a block defining what your API should do when this endpoint is hit
    def initialize(new_settings, options = {}, &block)
      require_option(options, :path)
      require_option(options, :method)

      self.inheritable_setting = new_settings.point_in_time_copy

      route_setting(:saved_declared_params, namespace_stackable(:declared_params))
      route_setting(:saved_validations, namespace_stackable(:validations))

      namespace_stackable(:representations, []) unless namespace_stackable(:representations)
      namespace_inheritable(:default_error_status, 500) unless namespace_inheritable(:default_error_status)

      @options = options

      @options[:path] = Array(options[:path])
      @options[:path] << '/' if options[:path].empty?

      @options[:method] = Array(options[:method])
      @options[:route_options] ||= {}

      @lazy_initialize_lock = Mutex.new
      @lazy_initialized = nil
      @block = nil

      @status = nil
      @file = nil
      @body = nil
      @proc = nil

      return unless block_given?

      @source = block
      @block = self.class.generate_api_method(method_name, &block)
    end

    # Update our settings from a given set of stackable parameters. Used when
    # the endpoint's API is mounted under another one.
    def inherit_settings(namespace_stackable)
      inheritable_setting.route[:saved_validations] += namespace_stackable[:validations]
      parent_declared_params = namespace_stackable[:declared_params]

      if parent_declared_params
        inheritable_setting.route[:declared_params] ||= []
        inheritable_setting.route[:declared_params].concat(parent_declared_params.flatten)
      end

      endpoints && endpoints.each { |e| e.inherit_settings(namespace_stackable) }
    end

    def require_option(options, key)
      raise Grape::Exceptions::MissingOption.new(key) unless options.key?(key)
    end

    def method_name
      [options[:method],
       Namespace.joined_space(namespace_stackable(:namespace)),
       (namespace_stackable(:mount_path) || []).join('/'),
       options[:path].join('/')]
        .join(' ')
    end

    def routes
      @routes ||= endpoints ? endpoints.collect(&:routes).flatten : to_routes
    end

    def reset_routes!
      endpoints.each(&:reset_routes!) if endpoints
      @namespace = nil
      @routes = nil
    end

    def mount_in(router)
      if endpoints
        endpoints.each { |e| e.mount_in(router) }
      else
        reset_routes!
        routes.each do |route|
          methods = [route.request_method]
          if !namespace_inheritable(:do_not_route_head) && route.request_method == Grape::Http::Headers::GET
            methods << Grape::Http::Headers::HEAD
          end
          methods.each do |method|
            unless route.request_method == method
              route = Grape::Router::Route.new(method, route.origin, **route.attributes.to_h)
            end
            router.append(route.apply(self))
          end
        end
      end
    end

    def to_routes
      route_options = prepare_default_route_attributes
      map_routes do |method, path|
        path = prepare_path(path)
        params = merge_route_options(**route_options.merge(suffix: path.suffix))
        route = Router::Route.new(method, path.path, **params)
        route.apply(self)
      end.flatten
    end

    def prepare_routes_requirements
      endpoint_requirements = options[:route_options][:requirements] || {}
      all_requirements = (namespace_stackable(:namespace).map(&:requirements) << endpoint_requirements)
      all_requirements.reduce({}) do |base_requirements, single_requirements|
        base_requirements.merge!(single_requirements)
      end
    end

    def prepare_default_route_attributes
      {
        namespace: namespace,
        version: prepare_version,
        requirements: prepare_routes_requirements,
        prefix: namespace_inheritable(:root_prefix),
        anchor: options[:route_options].fetch(:anchor, true),
        settings: inheritable_setting.route.except(:saved_declared_params, :saved_validations),
        forward_match: options[:forward_match]
      }
    end

    def prepare_version
      version = namespace_inheritable(:version) || []
      return if version.empty?
      version.length == 1 ? version.first.to_s : version
    end

    def merge_route_options(**default)
      options[:route_options].clone.merge!(**default)
    end

    def map_routes
      options[:method].map { |method| options[:path].map { |path| yield method, path } }
    end

    def prepare_path(path)
      path_settings = inheritable_setting.to_hash[:namespace_stackable].merge(inheritable_setting.to_hash[:namespace_inheritable])
      Path.prepare(path, namespace, path_settings)
    end

    def namespace
      @namespace ||= Namespace.joined_space_path(namespace_stackable(:namespace))
    end

    def call(env)
      lazy_initialize!
      dup.call!(env)
    end

    def call!(env)
      env[Grape::Env::API_ENDPOINT] = self
      @env = env
      @app.call(env)
    end

    # Return the collection of endpoints within this endpoint.
    # This is the case when an Grape::API mounts another Grape::API.
    def endpoints
      options[:app].endpoints if options[:app] && options[:app].respond_to?(:endpoints)
    end

    def equals?(e)
      (options == e.options) && (inheritable_setting.to_hash == e.inheritable_setting.to_hash)
    end

    protected

    def run
      ActiveSupport::Notifications.instrument('endpoint_run.grape', endpoint: self, env: env) do
        @header = {}
        @request = Grape::Request.new(env, build_params_with: namespace_inheritable(:build_params_with))
        @params = @request.params
        @headers = @request.headers
        begin
          cookies.read(@request)
          self.class.run_before_each(self)
          run_filters befores, :before

          if (allowed_methods = env[Grape::Env::GRAPE_ALLOWED_METHODS])
            raise Grape::Exceptions::MethodNotAllowed, header.merge('Allow' => allowed_methods) unless options?
            header 'Allow', allowed_methods
            response_object = ''
            status 204
          else
            run_filters before_validations, :before_validation
            run_validators validations, request
            remove_renamed_params
            run_filters after_validations, :after_validation
            response_object = execute
          end

          run_filters afters, :after
          cookies.write(header)

          # status verifies body presence when DELETE
          @body ||= response_object

          # The body commonly is an Array of Strings, the application instance itself, or a File-like object
          response_object = file || [body]

          [status, header, response_object]
        ensure
          run_filters finallies, :finally
        end
      end
    end

    def build_stack(helpers)
      stack = Grape::Middleware::Stack.new

      stack.use Rack::Head
      stack.use Class.new(Grape::Middleware::Error),
                helpers: helpers,
                format: namespace_inheritable(:format),
                content_types: namespace_stackable_with_hash(:content_types),
                default_status: namespace_inheritable(:default_error_status),
                rescue_all: namespace_inheritable(:rescue_all),
                rescue_grape_exceptions: namespace_inheritable(:rescue_grape_exceptions),
                default_error_formatter: namespace_inheritable(:default_error_formatter),
                error_formatters: namespace_stackable_with_hash(:error_formatters),
                rescue_options: namespace_stackable_with_hash(:rescue_options) || {},
                rescue_handlers: namespace_reverse_stackable_with_hash(:rescue_handlers) || {},
                base_only_rescue_handlers: namespace_stackable_with_hash(:base_only_rescue_handlers) || {},
                all_rescue_handler: namespace_inheritable(:all_rescue_handler)

      stack.concat namespace_stackable(:middleware)

      if namespace_inheritable(:version)
        stack.use Grape::Middleware::Versioner.using(namespace_inheritable(:version_options)[:using]),
                  versions: namespace_inheritable(:version) ? namespace_inheritable(:version).flatten : nil,
                  version_options: namespace_inheritable(:version_options),
                  prefix: namespace_inheritable(:root_prefix),
                  mount_path: namespace_stackable(:mount_path).first
      end

      stack.use Grape::Middleware::Formatter,
                format: namespace_inheritable(:format),
                default_format: namespace_inheritable(:default_format) || :txt,
                content_types: namespace_stackable_with_hash(:content_types),
                formatters: namespace_stackable_with_hash(:formatters),
                parsers: namespace_stackable_with_hash(:parsers)

      builder = stack.build
      builder.run ->(env) { env[Grape::Env::API_ENDPOINT].run }
      builder.to_app
    end

    def build_helpers
      helpers = namespace_stackable(:helpers) || []
      Module.new { helpers.each { |mod_to_include| include mod_to_include } }
    end

    def remove_renamed_params
      return unless route_setting(:renamed_params)
      route_setting(:renamed_params).flat_map(&:keys).each do |renamed_param|
        @params.delete(renamed_param)
      end
    end

    private :build_stack, :build_helpers, :remove_renamed_params

    def execute
      @block ? @block.call(self) : nil
    end

    def helpers
      lazy_initialize! && @helpers
    end

    def lazy_initialize!
      return true if @lazy_initialized

      @lazy_initialize_lock.synchronize do
        return true if @lazy_initialized

        @helpers = build_helpers.tap { |mod| self.class.send(:include, mod) }
        @app = options[:app] || build_stack(@helpers)

        @lazy_initialized = true
      end
    end

    def run_validators(validator_factories, request)
      validation_errors = []

      validators = validator_factories.map { |options| Grape::Validations::ValidatorFactory.create_validator(**options) }

      ActiveSupport::Notifications.instrument('endpoint_run_validators.grape', endpoint: self, validators: validators, request: request) do
        validators.each do |validator|
          begin
            validator.validate(request)
          rescue Grape::Exceptions::Validation => e
            validation_errors << e
            break if validator.fail_fast?
          rescue Grape::Exceptions::ValidationArrayErrors => e
            validation_errors.concat e.errors
            break if validator.fail_fast?
          end
        end
      end

      validation_errors.any? && raise(Grape::Exceptions::ValidationErrors.new(errors: validation_errors, headers: header))
    end

    def run_filters(filters, type = :other)
      ActiveSupport::Notifications.instrument('endpoint_run_filters.grape', endpoint: self, filters: filters, type: type) do
        (filters || []).each { |filter| instance_eval(&filter) }
      end
      post_extension = DSL::InsideRoute.post_filter_methods(type)
      extend post_extension if post_extension
    end

    def befores
      namespace_stackable(:befores) || []
    end

    def before_validations
      namespace_stackable(:before_validations) || []
    end

    def after_validations
      namespace_stackable(:after_validations) || []
    end

    def afters
      namespace_stackable(:afters) || []
    end

    def finallies
      namespace_stackable(:finallies) || []
    end

    def validations
      route_setting(:saved_validations) || []
    end

    def options?
      options[:options_route_enabled] &&
        env[Grape::Http::Headers::REQUEST_METHOD] == Grape::Http::Headers::OPTIONS
    end
  end
end
