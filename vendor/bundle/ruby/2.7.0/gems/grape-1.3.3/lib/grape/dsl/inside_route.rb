# frozen_string_literal: true

require 'active_support/concern'
require 'grape/dsl/headers'

module Grape
  module DSL
    module InsideRoute
      extend ActiveSupport::Concern
      include Grape::DSL::Settings
      include Grape::DSL::Headers

      # Denotes a situation where a DSL method has been invoked in a
      # filter which it should not yet be available in
      class MethodNotYetAvailable < StandardError; end

      # @param type [Symbol] The type of filter for which evaluation has been
      #   completed
      # @return [Module] A module containing method overrides suitable for the
      #   position in the filter evaluation sequence denoted by +type+.  This
      #   defaults to an empty module if no overrides are defined for the given
      #   filter +type+.
      def self.post_filter_methods(type)
        @post_filter_modules ||= { before: PostBeforeFilter }
        @post_filter_modules[type]
      end

      # Methods which should not be available in filters until the before filter
      # has completed
      module PostBeforeFilter
        def declared(passed_params, options = {}, declared_params = nil, params_nested_path = [])
          options = options.reverse_merge(include_missing: true, include_parent_namespaces: true)
          declared_params ||= optioned_declared_params(**options)

          if passed_params.is_a?(Array)
            declared_array(passed_params, options, declared_params, params_nested_path)
          else
            declared_hash(passed_params, options, declared_params, params_nested_path)
          end
        end

        private

        def declared_array(passed_params, options, declared_params, params_nested_path)
          passed_params.map do |passed_param|
            declared(passed_param || {}, options, declared_params, params_nested_path)
          end
        end

        def declared_hash(passed_params, options, declared_params, params_nested_path)
          declared_params.each_with_object(passed_params.class.new) do |declared_param, memo|
            if declared_param.is_a?(Hash)
              declared_param.each_pair do |declared_parent_param, declared_children_params|
                params_nested_path_dup = params_nested_path.dup
                params_nested_path_dup << declared_parent_param.to_s
                next unless options[:include_missing] || passed_params.key?(declared_parent_param)

                passed_children_params = passed_params[declared_parent_param] || passed_params.class.new
                memo_key = optioned_param_key(declared_parent_param, options)

                memo[memo_key] = handle_passed_param(passed_children_params, params_nested_path_dup) do
                  declared(passed_children_params, options, declared_children_params, params_nested_path_dup)
                end
              end
            else
              # If it is not a Hash then it does not have children.
              # Find its value or set it to nil.
              has_renaming = route_setting(:renamed_params) && route_setting(:renamed_params).find { |current| current[declared_param] }
              param_renaming = has_renaming[declared_param] if has_renaming

              next unless options[:include_missing] || passed_params.key?(declared_param) || (param_renaming && passed_params.key?(param_renaming))

              if param_renaming
                memo[optioned_param_key(param_renaming, options)] = passed_params[param_renaming]
              else
                memo[optioned_param_key(declared_param, options)] = passed_params[declared_param]
              end
            end
          end
        end

        def handle_passed_param(passed_children_params, params_nested_path, &_block)
          if should_be_empty_hash?(passed_children_params, params_nested_path)
            {}
          elsif should_be_empty_array?(passed_children_params, params_nested_path)
            []
          else
            yield
          end
        end

        def should_be_empty_array?(passed_children_params, params_nested_path)
          passed_children_params.empty? && declared_param_is_array?(params_nested_path)
        end

        def declared_param_is_array?(params_nested_path)
          key = route_options_params_key(params_nested_path)
          route_options_params[key] && route_options_params[key][:type] == 'Array'
        end

        def should_be_empty_hash?(passed_children_params, params_nested_path)
          passed_children_params.empty? && declared_param_is_hash?(params_nested_path)
        end

        def declared_param_is_hash?(params_nested_path)
          key = route_options_params_key(params_nested_path)
          route_options_params[key] && route_options_params[key][:type] == 'Hash'
        end

        def route_options_params
          options[:route_options][:params] || {}
        end

        def optioned_param_key(declared_param, options)
          options[:stringify] ? declared_param.to_s : declared_param.to_sym
        end

        def route_options_params_key(params_nested_path)
          key = params_nested_path[0]
          key += '[' + params_nested_path[1..-1].join('][') + ']' if params_nested_path.size > 1
          key
        end

        def optioned_declared_params(**options)
          declared_params = if options[:include_parent_namespaces]
                              # Declared params including parent namespaces
                              route_setting(:saved_declared_params).flatten | Array(route_setting(:declared_params))
                            else
                              # Declared params at current namespace
                              route_setting(:saved_declared_params).last & Array(route_setting(:declared_params))
                            end

          raise ArgumentError, 'Tried to filter for declared parameters but none exist.' unless declared_params
          declared_params
        end
      end

      # A filtering method that will return a hash
      # consisting only of keys that have been declared by a
      # `params` statement against the current/target endpoint or parent
      # namespaces.
      #
      # @see +PostBeforeFilter#declared+
      #
      # @param params [Hash] The initial hash to filter. Usually this will just be `params`
      # @param options [Hash] Can pass `:include_missing`, `:stringify` and `:include_parent_namespaces`
      # options. `:include_parent_namespaces` defaults to true, hence must be set to false if
      # you want only to return params declared against the current/target endpoint.
      def declared(*)
        raise MethodNotYetAvailable, '#declared is not available prior to parameter validation.'
      end

      # The API version as specified in the URL.
      def version
        env[Grape::Env::API_VERSION]
      end

      def configuration
        options[:for].configuration.evaluate
      end

      # End the request and display an error to the
      # end user with the specified message.
      #
      # @param message [String] The message to display.
      # @param status [Integer] the HTTP Status Code. Defaults to default_error_status, 500 if not set.
      # @param additional_headers [Hash] Addtional headers for the response.
      def error!(message, status = nil, additional_headers = nil)
        self.status(status || namespace_inheritable(:default_error_status))
        headers = additional_headers.present? ? header.merge(additional_headers) : header
        throw :error, message: message, status: self.status, headers: headers
      end

      # Redirect to a new url.
      #
      # @param url [String] The url to be redirect.
      # @param options [Hash] The options used when redirect.
      #                       :permanent, default false.
      #                       :body, default a short message including the URL.
      def redirect(url, permanent: false, body: nil, **_options)
        body_message = body
        if permanent
          status 301
          body_message ||= "This resource has been moved permanently to #{url}."
        elsif env[Grape::Http::Headers::HTTP_VERSION] == 'HTTP/1.1' && request.request_method.to_s.upcase != Grape::Http::Headers::GET
          status 303
          body_message ||= "An alternate resource is located at #{url}."
        else
          status 302
          body_message ||= "This resource has been moved temporarily to #{url}."
        end
        header 'Location', url
        content_type 'text/plain'
        body body_message
      end

      # Set or retrieve the HTTP status code.
      #
      # @param status [Integer] The HTTP Status Code to return for this request.
      def status(status = nil)
        case status
        when Symbol
          raise ArgumentError, "Status code :#{status} is invalid." unless Rack::Utils::SYMBOL_TO_STATUS_CODE.key?(status)
          @status = Rack::Utils.status_code(status)
        when Integer
          @status = status
        when nil
          return @status if instance_variable_defined?(:@status) && @status
          case request.request_method.to_s.upcase
          when Grape::Http::Headers::POST
            201
          when Grape::Http::Headers::DELETE
            if instance_variable_defined?(:@body) && @body.present?
              200
            else
              204
            end
          else
            200
          end
        else
          raise ArgumentError, 'Status code must be Integer or Symbol.'
        end
      end

      # Set response content-type
      def content_type(val = nil)
        if val
          header(Grape::Http::Headers::CONTENT_TYPE, val)
        else
          header[Grape::Http::Headers::CONTENT_TYPE]
        end
      end

      # Set or get a cookie
      #
      # @example
      #   cookies[:mycookie] = 'mycookie val'
      #   cookies['mycookie-string'] = 'mycookie string val'
      #   cookies[:more] = { value: '123', expires: Time.at(0) }
      #   cookies.delete :more
      #
      def cookies
        @cookies ||= Cookies.new
      end

      # Allows you to define the response body as something other than the
      # return value.
      #
      # @example
      #   get '/body' do
      #     body "Body"
      #     "Not the Body"
      #   end
      #
      #   GET /body # => "Body"
      def body(value = nil)
        if value
          @body = value
        elsif value == false
          @body = ''
          status 204
        else
          instance_variable_defined?(:@body) ? @body : nil
        end
      end

      # Allows you to explicitly return no content.
      #
      # @example
      #   delete :id do
      #     return_no_content
      #     "not returned"
      #   end
      #
      #   DELETE /12 # => 204 No Content, ""
      def return_no_content
        status 204
        body false
      end

      # Allows you to define the response as a file-like object.
      #
      # @example
      #   get '/file' do
      #     file FileStreamer.new(...)
      #   end
      #
      #   GET /file # => "contents of file"
      def file(value = nil)
        if value.is_a?(String)
          file_body = Grape::ServeFile::FileBody.new(value)
          @file = Grape::ServeFile::FileResponse.new(file_body)
        elsif !value.is_a?(NilClass)
          warn '[DEPRECATION] Argument as FileStreamer-like object is deprecated. Use path to file instead.'
          @file = Grape::ServeFile::FileResponse.new(value)
        else
          instance_variable_defined?(:@file) ? @file : nil
        end
      end

      # Allows you to define the response as a streamable object.
      #
      # If Content-Length and Transfer-Encoding are blank (among other conditions),
      # Rack assumes this response can be streamed in chunks.
      #
      # @example
      #   get '/stream' do
      #     stream FileStreamer.new(...)
      #   end
      #
      #   GET /stream # => "chunked contents of file"
      #
      # See:
      # * https://github.com/rack/rack/blob/99293fa13d86cd48021630fcc4bd5acc9de5bdc3/lib/rack/chunked.rb
      # * https://github.com/rack/rack/blob/99293fa13d86cd48021630fcc4bd5acc9de5bdc3/lib/rack/etag.rb
      def stream(value = nil)
        header 'Content-Length', nil
        header 'Transfer-Encoding', nil
        header 'Cache-Control', 'no-cache' # Skips ETag generation (reading the response up front)
        file(value)
      end

      # Allows you to make use of Grape Entities by setting
      # the response body to the serializable hash of the
      # entity provided in the `:with` option. This has the
      # added benefit of automatically passing along environment
      # and version information to the serialization, making it
      # very easy to do conditional exposures. See Entity docs
      # for more info.
      #
      # @example
      #
      #   get '/users/:id' do
      #     present User.find(params[:id]),
      #       with: API::Entities::User,
      #       admin: current_user.admin?
      #   end
      def present(*args)
        options = args.count > 1 ? args.extract_options! : {}
        key, object = if args.count == 2 && args.first.is_a?(Symbol)
                        args
                      else
                        [nil, args.first]
                      end
        entity_class = entity_class_for_obj(object, options)

        root = options.delete(:root)

        representation = if entity_class
                           entity_representation_for(entity_class, object, options)
                         else
                           object
                         end

        representation = { root => representation } if root

        if key
          representation = (body || {}).merge(key => representation)
        elsif entity_class.present? && body
          raise ArgumentError, "Representation of type #{representation.class} cannot be merged." unless representation.respond_to?(:merge)
          representation = body.merge(representation)
        end

        body representation
      end

      # Returns route information for the current request.
      #
      # @example
      #
      #   desc "Returns the route description."
      #   get '/' do
      #     route.description
      #   end
      def route
        env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
      end

      # Attempt to locate the Entity class for a given object, if not given
      # explicitly. This is done by looking for the presence of Klass::Entity,
      # where Klass is the class of the `object` parameter, or one of its
      # ancestors.
      # @param object [Object] the object to locate the Entity class for
      # @param options [Hash]
      # @option options :with [Class] the explicit entity class to use
      # @return [Class] the located Entity class, or nil if none is found
      def entity_class_for_obj(object, options)
        entity_class = options.delete(:with)

        if entity_class.nil?
          # entity class not explicitely defined, auto-detect from relation#klass or first object in the collection
          object_class = if object.respond_to?(:klass)
                           object.klass
                         else
                           object.respond_to?(:first) ? object.first.class : object.class
                         end

          object_class.ancestors.each do |potential|
            entity_class ||= (namespace_stackable_with_hash(:representations) || {})[potential]
          end

          entity_class ||= object_class.const_get(:Entity) if object_class.const_defined?(:Entity) && object_class.const_get(:Entity).respond_to?(:represent)
        end

        entity_class
      end

      # @return the representation of the given object as done through
      #   the given entity_class.
      def entity_representation_for(entity_class, object, options)
        embeds = { env: env }
        embeds[:version] = env[Grape::Env::API_VERSION] if env[Grape::Env::API_VERSION]
        entity_class.represent(object, embeds.merge(options))
      end
    end
  end
end
