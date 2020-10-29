# frozen_string_literal: true

require 'active_support/concern'

module Grape
  module DSL
    module Routing
      extend ActiveSupport::Concern
      include Grape::DSL::Configuration

      module ClassMethods
        attr_reader :endpoints

        # Specify an API version.
        #
        # @example API with legacy support.
        #   class MyAPI < Grape::API
        #     version 'v2'
        #
        #     get '/main' do
        #       {some: 'data'}
        #     end
        #
        #     version 'v1' do
        #       get '/main' do
        #         {legacy: 'data'}
        #       end
        #     end
        #   end
        #
        def version(*args, &block)
          if args.any?
            options = args.extract_options!
            options = options.reverse_merge(using: :path)
            requested_versions = args.flatten

            raise Grape::Exceptions::MissingVendorOption.new if options[:using] == :header && !options.key?(:vendor)

            @versions = versions | requested_versions

            if block_given?
              within_namespace do
                namespace_inheritable(:version, requested_versions)
                namespace_inheritable(:version_options, options)

                instance_eval(&block)
              end
            else
              namespace_inheritable(:version, requested_versions)
              namespace_inheritable(:version_options, options)
            end
          end

          @versions.last if instance_variable_defined?(:@versions) && @versions
        end

        # Define a root URL prefix for your entire API.
        def prefix(prefix = nil)
          namespace_inheritable(:root_prefix, prefix)
        end

        # Create a scope without affecting the URL.
        #
        # @param _name [Symbol] Purely placebo, just allows to name the scope to
        # make the code more readable.
        def scope(_name = nil, &block)
          within_namespace do
            nest(block)
          end
        end

        # Do not route HEAD requests to GET requests automatically.
        def do_not_route_head!
          namespace_inheritable(:do_not_route_head, true)
        end

        # Do not automatically route OPTIONS.
        def do_not_route_options!
          namespace_inheritable(:do_not_route_options, true)
        end

        def mount(mounts, opts = {})
          mounts = { mounts => '/' } unless mounts.respond_to?(:each_pair)
          mounts.each_pair do |app, path|
            if app.respond_to?(:mount_instance)
              mount(app.mount_instance(configuration: opts[:with] || {}) => path)
              next
            end
            in_setting = inheritable_setting

            if app.respond_to?(:inheritable_setting, true)
              mount_path = Grape::Router.normalize_path(path)
              app.top_level_setting.namespace_stackable[:mount_path] = mount_path

              app.inherit_settings(inheritable_setting)

              in_setting = app.top_level_setting

              app.change!
              change!
            end

            endpoints << Grape::Endpoint.new(
              in_setting,
              method: :any,
              path: path,
              app: app,
              route_options: { anchor: false },
              forward_match: !app.respond_to?(:inheritable_setting),
              for: self
            )
          end
        end

        # Defines a route that will be recognized
        # by the Grape API.
        #
        # @param methods [HTTP Verb] One or more HTTP verbs that are accepted by this route. Set to `:any` if you want any verb to be accepted.
        # @param paths [String] One or more strings representing the URL segment(s) for this route.
        #
        # @example Defining a basic route.
        #   class MyAPI < Grape::API
        #     route(:any, '/hello') do
        #       {hello: 'world'}
        #     end
        #   end
        def route(methods, paths = ['/'], route_options = {}, &block)
          methods = '*' if methods == :any
          endpoint_options = {
            method: methods,
            path: paths,
            for: self,
            route_options: {
              params: namespace_stackable_with_hash(:params) || {}
            }.deep_merge(route_setting(:description) || {}).deep_merge(route_options || {})
          }

          new_endpoint = Grape::Endpoint.new(inheritable_setting, endpoint_options, &block)
          endpoints << new_endpoint unless endpoints.any? { |e| e.equals?(new_endpoint) }

          route_end
          reset_validations!
        end

        Grape::Http::Headers::SUPPORTED_METHODS.each do |supported_method|
          define_method supported_method.downcase do |*args, &block|
            options = args.extract_options!
            paths = args.first || ['/']
            route(supported_method, paths, options, &block)
          end
        end

        # Declare a "namespace", which prefixes all subordinate routes with its
        # name. Any endpoints within a namespace, or group, resource, segment,
        # etc., will share their parent context as well as any configuration
        # done in the namespace context.
        #
        # @example
        #
        #     namespace :foo do
        #       get 'bar' do
        #         # defines the endpoint: GET /foo/bar
        #       end
        #     end
        def namespace(space = nil, options = {}, &block)
          @namespace_description = nil unless instance_variable_defined?(:@namespace_description) && @namespace_description

          if space || block_given?
            within_namespace do
              previous_namespace_description = @namespace_description
              @namespace_description = (@namespace_description || {}).deep_merge(namespace_setting(:description) || {})
              nest(block) do
                if space
                  namespace_stackable(:namespace, Namespace.new(space, **options))
                end
              end
              @namespace_description = previous_namespace_description
            end
          else
            Namespace.joined_space_path(namespace_stackable(:namespace))
          end
        end

        alias group namespace
        alias resource namespace
        alias resources namespace
        alias segment namespace

        # An array of API routes.
        def routes
          @routes ||= prepare_routes
        end

        # Remove all defined routes.
        def reset_routes!
          endpoints.each(&:reset_routes!)
          @routes = nil
        end

        def reset_endpoints!
          @endpoints = []
        end

        # Thie method allows you to quickly define a parameter route segment
        # in your API.
        #
        # @param param [Symbol] The name of the parameter you wish to declare.
        # @option options [Regexp] You may supply a regular expression that the declared parameter must meet.
        def route_param(param, options = {}, &block)
          options = options.dup

          options[:requirements] = {
            param.to_sym => options[:requirements]
          } if options[:requirements].is_a?(Regexp)

          Grape::Validations::ParamsScope.new(api: self) do
            requires param, type: options[:type]
          end if options.key?(:type)

          namespace(":#{param}", options, &block)
        end

        # @return array of defined versions
        def versions
          @versions ||= []
        end
      end
    end
  end
end
