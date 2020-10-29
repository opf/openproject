# frozen_string_literal: true

require 'active_support/concern'

module Grape
  module DSL
    # Defines DSL methods, meant to be applied to a ParamsScope, which define
    # and describe the parameters accepted by an endpoint, or all endpoints
    # within a namespace.
    module Parameters
      extend ActiveSupport::Concern

      # Set the module used to build the request.params.
      #
      # @param build_with the ParamBuilder module to use when building request.params
      #   Available builders are:
      #
      #     * Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder (default)
      #     * Grape::Extensions::Hash::ParamBuilder
      #     * Grape::Extensions::Hashie::Mash::ParamBuilder
      #
      # @example
      #
      #     require 'grape/extenstions/hashie_mash'
      #     class API < Grape::API
      #       desc "Get collection"
      #       params do
      #         build_with Grape::Extensions::Hashie::Mash::ParamBuilder
      #         requires :user_id, type: Integer
      #       end
      #       get do
      #         params['user_id']
      #       end
      #     end
      def build_with(build_with = nil)
        @api.namespace_inheritable(:build_params_with, build_with)
      end

      # Include reusable params rules among current.
      # You can define reusable params with helpers method.
      #
      # @example
      #
      #     class API < Grape::API
      #       helpers do
      #         params :pagination do
      #           optional :page, type: Integer
      #           optional :per_page, type: Integer
      #         end
      #       end
      #
      #       desc "Get collection"
      #       params do
      #         use :pagination
      #       end
      #       get do
      #         Collection.page(params[:page]).per(params[:per_page])
      #       end
      #     end
      def use(*names)
        named_params = @api.namespace_stackable_with_hash(:named_params) || {}
        options = names.extract_options!
        names.each do |name|
          params_block = named_params.fetch(name) do
            raise "Params :#{name} not found!"
          end
          instance_exec(options, &params_block)
        end
      end
      alias use_scope use
      alias includes use

      # Require one or more parameters for the current endpoint.
      #
      # @param attrs list of parameter names, or, if :using is
      #   passed as an option, which keys to include (:all or :none) from
      #   the :using hash. The last key can be a hash, which specifies
      #   options for the parameters
      # @option attrs :type [Class] the type to coerce this parameter to before
      #   passing it to the endpoint. See {Grape::Validations::Types} for a list of
      #   types that are supported automatically. Custom classes may be used
      #   where they define a class-level `::parse` method, or in conjunction
      #   with the `:coerce_with` parameter. `JSON` may be supplied to denote
      #   `JSON`-formatted objects or arrays of objects. `Array[JSON]` accepts
      #   the same values as `JSON` but will wrap single objects in an `Array`.
      # @option attrs :types [Array<Class>] may be supplied in place of +:type+
      #   to declare an attribute that has multiple allowed types. See
      #   {Validations::Types::MultipleTypeCoercer} for more details on coercion
      #   and validation rules for variant-type parameters.
      # @option attrs :desc [String] description to document this parameter
      # @option attrs :default [Object] default value, if parameter is optional
      # @option attrs :values [Array] permissable values for this field. If any
      #   other value is given, it will be handled as a validation error
      # @option attrs :using [Hash[Symbol => Hash]] a hash defining keys and
      #   options, like that returned by {Grape::Entity#documentation}. The value
      #   of each key is an options hash accepting the same parameters
      # @option attrs :except [Array[Symbol]] a list of keys to exclude from
      #   the :using Hash. The meaning of this depends on if :all or :none was
      #   passed; :all + :except will make the :except fields optional, whereas
      #   :none + :except will make the :except fields required
      # @option attrs :coerce_with [#parse, #call] method to be used when coercing
      #   the parameter to the type named by `attrs[:type]`. Any class or object
      #   that defines `::parse` or `::call` may be used.
      #
      # @example
      #
      #     params do
      #       # Basic usage: require a parameter of a certain type
      #       requires :user_id, type: Integer
      #
      #       # You don't need to specify type; String is default
      #       requires :foo
      #
      #       # Multiple params can be specified at once if they share
      #       # the same options.
      #       requires :x, :y, :z, type: Date
      #
      #       # Nested parameters can be handled as hashes. You must
      #       # pass in a block, within which you can use any of the
      #       # parameters DSL methods.
      #       requires :user, type: Hash do
      #         requires :name, type: String
      #       end
      #     end
      def requires(*attrs, &block)
        orig_attrs = attrs.clone

        opts = attrs.extract_options!.clone
        opts[:presence] = { value: true, message: opts[:message] }
        opts = @group.merge(opts) if instance_variable_defined?(:@group) && @group

        if opts[:using]
          require_required_and_optional_fields(attrs.first, opts)
        else
          validate_attributes(attrs, opts, &block)
          block_given? ? new_scope(orig_attrs, &block) : push_declared_params(attrs, **opts.slice(:as))
        end
      end

      # Allow, but don't require, one or more parameters for the current
      #   endpoint.
      # @param (see #requires)
      # @option (see #requires)
      def optional(*attrs, &block)
        orig_attrs = attrs.clone

        opts = attrs.extract_options!.clone
        type = opts[:type]
        opts = @group.merge(opts) if instance_variable_defined?(:@group) && @group

        # check type for optional parameter group
        if attrs && block_given?
          raise Grape::Exceptions::MissingGroupTypeError.new if type.nil?
          raise Grape::Exceptions::UnsupportedGroupTypeError.new unless Grape::Validations::Types.group?(type)
        end

        if opts[:using]
          require_optional_fields(attrs.first, opts)
        else
          validate_attributes(attrs, opts, &block)

          block_given? ? new_scope(orig_attrs, true, &block) : push_declared_params(attrs, **opts.slice(:as))
        end
      end

      # Define common settings for one or more parameters
      # @param (see #requires)
      # @option (see #requires)
      def with(*attrs, &block)
        new_group_scope(attrs.clone, &block)
      end

      # Disallow the given parameters to be present in the same request.
      # @param attrs [*Symbol] parameters to validate
      def mutually_exclusive(*attrs)
        validates(attrs, mutual_exclusion: { value: true, message: extract_message_option(attrs) })
      end

      # Require exactly one of the given parameters to be present.
      # @param (see #mutually_exclusive)
      def exactly_one_of(*attrs)
        validates(attrs, exactly_one_of: { value: true, message: extract_message_option(attrs) })
      end

      # Require at least one of the given parameters to be present.
      # @param (see #mutually_exclusive)
      def at_least_one_of(*attrs)
        validates(attrs, at_least_one_of: { value: true, message: extract_message_option(attrs) })
      end

      # Require that either all given params are present, or none are.
      # @param (see #mutually_exclusive)
      def all_or_none_of(*attrs)
        validates(attrs, all_or_none_of: { value: true, message: extract_message_option(attrs) })
      end

      # Define a block of validations which should be applied if and only if
      # the given parameter is present. The parameters are not nested.
      # @param attr [Symbol] the parameter which, if present, triggers the
      #   validations
      # @raise Grape::Exceptions::UnknownParameter if `attr` has not been
      #   defined in this scope yet
      # @yield a parameter definition DSL
      def given(*attrs, &block)
        attrs.each do |attr|
          proxy_attr = first_hash_key_or_param(attr)
          raise Grape::Exceptions::UnknownParameter.new(proxy_attr) unless declared_param?(proxy_attr)
        end
        new_lateral_scope(dependent_on: attrs, &block)
      end

      # Test for whether a certain parameter has been defined in this params
      # block yet.
      # @return [Boolean] whether the parameter has been defined
      def declared_param?(param)
        if lateral?
          # Elements of @declared_params of lateral scope are pushed in @parent. So check them in @parent.
          @parent.declared_param?(param)
        else
          # @declared_params also includes hashes of options and such, but those
          # won't be flattened out.
          @declared_params.flatten.any? do |declared_param|
            first_hash_key_or_param(declared_param) == param
          end
        end
      end

      alias group requires

      def map_params(params, element)
        if params.is_a?(Array)
          params.map do |el|
            map_params(el, element)
          end
        elsif params.is_a?(Hash)
          params[element] || {}
        else
          {}
        end
      end

      # @param params [Hash] initial hash of parameters
      # @return hash of parameters relevant for the current scope
      # @api private
      def params(params)
        params = @parent.params(params) if instance_variable_defined?(:@parent) && @parent
        params = map_params(params, @element) if instance_variable_defined?(:@element) && @element
        params
      end

      private

      def first_hash_key_or_param(parameter)
        parameter.is_a?(Hash) ? parameter.keys.first : parameter
      end
    end
  end
end
