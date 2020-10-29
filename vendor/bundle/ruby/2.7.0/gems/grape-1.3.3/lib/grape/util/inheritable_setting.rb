# frozen_string_literal: true

module Grape
  module Util
    # A branchable, inheritable settings object which can store both stackable
    # and inheritable values (see InheritableValues and StackableValues).
    class InheritableSetting
      attr_accessor :route, :api_class, :namespace
      attr_accessor :namespace_inheritable, :namespace_stackable, :namespace_reverse_stackable
      attr_accessor :parent, :point_in_time_copies

      # Retrieve global settings.
      def self.global
        @global ||= {}
      end

      # Clear all global settings.
      # @api private
      # @note only for testing
      def self.reset_global!
        @global = {}
      end

      # Instantiate a new settings instance, with blank values. The fresh
      # instance can then be set to inherit from an existing instance (see
      # #inherit_from).
      def initialize
        self.route = {}
        self.api_class = {}
        self.namespace = InheritableValues.new # only inheritable from a parent when
        # used with a mount, or should every API::Class be a separate namespace by default?
        self.namespace_inheritable = InheritableValues.new
        self.namespace_stackable = StackableValues.new
        self.namespace_reverse_stackable = ReverseStackableValues.new

        self.point_in_time_copies = []

        self.parent = nil
      end

      # Return the class-level global properties.
      def global
        self.class.global
      end

      # Set our inherited values to the given parent's current values. Also,
      # update the inherited values on any settings instances which were forked
      # from us.
      # @param parent [InheritableSetting]
      def inherit_from(parent)
        return if parent.nil?

        self.parent = parent

        namespace_inheritable.inherited_values = parent.namespace_inheritable
        namespace_stackable.inherited_values = parent.namespace_stackable
        namespace_reverse_stackable.inherited_values = parent.namespace_reverse_stackable
        self.route = parent.route.merge(route)

        point_in_time_copies.map { |cloned_one| cloned_one.inherit_from parent }
      end

      # Create a point-in-time copy of this settings instance, with clones of
      # all our values. Note that, should this instance's parent be set or
      # changed via #inherit_from, it will copy that inheritence to any copies
      # which were made.
      def point_in_time_copy
        self.class.new.tap do |new_setting|
          point_in_time_copies << new_setting
          new_setting.point_in_time_copies = []

          new_setting.namespace = namespace.clone
          new_setting.namespace_inheritable = namespace_inheritable.clone
          new_setting.namespace_stackable = namespace_stackable.clone
          new_setting.namespace_reverse_stackable = namespace_reverse_stackable.clone
          new_setting.route = route.clone
          new_setting.api_class = api_class

          new_setting.inherit_from(parent)
        end
      end

      # Resets the instance store of per-route settings.
      # @api private
      def route_end
        @route = {}
      end

      # Return a serializable hash of our values.
      def to_hash
        {
          global: global.clone,
          route: route.clone,
          namespace: namespace.to_hash,
          namespace_inheritable: namespace_inheritable.to_hash,
          namespace_stackable: namespace_stackable.to_hash,
          namespace_reverse_stackable: namespace_reverse_stackable.to_hash
        }
      end
    end
  end
end
