# frozen_string_literal: true

require 'active_support/concern'

module Grape
  module DSL
    # Keeps track of settings (implemented as key-value pairs, grouped by
    # types), in two contexts: top-level settings which apply globally no
    # matter where they're defined, and inheritable settings which apply only
    # in the current scope and scopes nested under it.
    module Settings
      extend ActiveSupport::Concern

      attr_writer :inheritable_setting, :top_level_setting

      # Fetch our top-level settings, which apply to all endpoints in the API.
      def top_level_setting
        @top_level_setting ||= build_top_level_setting
      end

      # Fetch our current inheritable settings, which are inherited by
      # nested scopes but not shared across siblings.
      def inheritable_setting
        @inheritable_setting ||= Grape::Util::InheritableSetting.new.tap { |new_settings| new_settings.inherit_from top_level_setting }
      end

      # @param type [Symbol]
      # @param key [Symbol]
      def unset(type, key)
        setting = inheritable_setting.send(type)
        setting.delete key
      end

      # @param type [Symbol]
      # @param key [Symbol]
      # @param value [Object] will be stored if the value is currently empty
      # @return either the old value, if it wasn't nil, or the given value
      def get_or_set(type, key, value)
        setting = inheritable_setting.send(type)
        if value.nil?
          setting[key]
        else
          setting[key] = value
        end
      end

      # @param key [Symbol]
      # @param value [Object]
      # @return (see #get_or_set)
      def global_setting(key, value = nil)
        get_or_set :global, key, value
      end

      # @param key [Symbol]
      def unset_global_setting(key)
        unset :global, key
      end

      # (see #global_setting)
      def route_setting(key, value = nil)
        get_or_set :route, key, value
      end

      # (see #unset_global_setting)
      def unset_route_setting(key)
        unset :route, key
      end

      # (see #global_setting)
      def namespace_setting(key, value = nil)
        get_or_set :namespace, key, value
      end

      # (see #unset_global_setting)
      def unset_namespace_setting(key)
        unset :namespace, key
      end

      # (see #global_setting)
      def namespace_inheritable(key, value = nil)
        get_or_set :namespace_inheritable, key, value
      end

      # (see #unset_global_setting)
      def unset_namespace_inheritable(key)
        unset :namespace_inheritable, key
      end

      # @param key [Symbol]
      def namespace_inheritable_to_nil(key)
        inheritable_setting.namespace_inheritable[key] = nil
      end

      # (see #global_setting)
      def namespace_stackable(key, value = nil)
        get_or_set :namespace_stackable, key, value
      end

      def namespace_reverse_stackable(key, value = nil)
        get_or_set :namespace_reverse_stackable, key, value
      end

      def namespace_stackable_with_hash(key)
        settings = get_or_set :namespace_stackable, key, nil
        return if settings.blank?
        settings.each_with_object({}) { |value, result| result.deep_merge!(value) }
      end

      def namespace_reverse_stackable_with_hash(key)
        settings = get_or_set :namespace_reverse_stackable, key, nil
        return if settings.blank?
        result = {}
        settings.each do |setting|
          setting.each do |field, value|
            result[field] ||= value
          end
        end
        result
      end

      # (see #unset_global_setting)
      def unset_namespace_stackable(key)
        unset :namespace_stackable, key
      end

      # (see #global_setting)
      def api_class_setting(key, value = nil)
        get_or_set :api_class, key, value
      end

      # (see #unset_global_setting)
      def unset_api_class_setting(key)
        unset :api_class, key
      end

      # Fork our inheritable settings to a new instance, copied from our
      # parent's, but separate so we won't modify it. Every call to this
      # method should have an answering call to #namespace_end.
      def namespace_start
        @inheritable_setting = Grape::Util::InheritableSetting.new.tap { |new_settings| new_settings.inherit_from inheritable_setting }
      end

      # Set the inheritable settings pointer back up by one level.
      def namespace_end
        route_end
        @inheritable_setting = inheritable_setting.parent
      end

      # Stop defining settings for the current route and clear them for the
      # next, within a namespace.
      def route_end
        inheritable_setting.route_end
      end

      # Execute the block within a context where our inheritable settings are forked
      # to a new copy (see #namespace_start).
      def within_namespace(&_block)
        namespace_start

        result = yield if block_given?

        namespace_end
        reset_validations!

        result
      end

      private

      # Builds the current class :inheritable_setting. If available, it inherits from
      # the superclass's :inheritable_setting.
      def build_top_level_setting
        Grape::Util::InheritableSetting.new.tap do |setting|
          # Doesn't try to inherit settings from +Grape::API::Instance+ which also responds to
          # +inheritable_setting+, however, it doesn't contain any user-defined settings.
          # Otherwise, it would lead to an extra instance of +Grape::Util::InheritableSetting+
          # in the chain for every endpoint.
          if defined?(superclass) && superclass.respond_to?(:inheritable_setting) && superclass != Grape::API::Instance
            setting.inherit_from superclass.inheritable_setting
          end
        end
      end
    end
  end
end
