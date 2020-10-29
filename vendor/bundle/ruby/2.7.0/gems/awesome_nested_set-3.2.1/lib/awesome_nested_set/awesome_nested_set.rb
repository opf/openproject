require 'awesome_nested_set/columns'
require 'awesome_nested_set/model'

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:

      # This provides Nested Set functionality. Nested Set is a smart way to implement
      # an _ordered_ tree, with the added feature that you can select the children and all of their
      # descendants with a single query. The drawback is that insertion or move need some complex
      # sql queries. But everything is done here by this module!
      #
      # Nested sets are appropriate each time you want either an orderd tree (menus,
      # commercial categories) or an efficient way of querying big trees (threaded posts).
      #
      # == API
      #
      # Methods names are aligned with acts_as_tree as much as possible to make transition from one
      # to another easier.
      #
      #   item.children.create(:name => "child1")
      #

      # Configuration options are:
      #
      # * +:parent_column+ - specifies the column name to use for keeping the position integer (default: parent_id)
      # * +:primary_column+ - specifies the column name to use as the inverse of the parent column (default: id)
      # * +:left_column+ - column name for left boundary data, default "lft"
      # * +:right_column+ - column name for right boundary data, default "rgt"
      # * +:depth_column+ - column name for the depth data, default "depth"
      # * +:scope+ - restricts what is to be considered a list. Given a symbol, it'll attach "_id"
      #   (if it hasn't been already) and use that as the foreign key restriction. You
      #   can also pass an array to scope by multiple attributes.
      #   Example: <tt>acts_as_nested_set :scope => [:notable_id, :notable_type]</tt>
      # * +:dependent+ - behavior for cascading destroy. If set to :destroy, all the
      #   child objects are destroyed alongside this object by calling their destroy
      #   method. If set to :delete_all (default), all the child objects are deleted
      #   without calling their destroy method.
      # * +:counter_cache+ adds a counter cache for the number of children.
      #   defaults to false.
      #   Example: <tt>acts_as_nested_set :counter_cache => :children_count</tt>
      # * +:order_column+ on which column to do sorting, by default it is the left_column_name
      #   Example: <tt>acts_as_nested_set :order_column => :position</tt>
      #
      # See CollectiveIdea::Acts::NestedSet::Model::ClassMethods for a list of class methods and
      # CollectiveIdea::Acts::NestedSet::Model for a list of instance methods added
      # to acts_as_nested_set models
      def acts_as_nested_set(options = {})
        acts_as_nested_set_parse_options! options

        include Model
        include Columns
        extend Columns

        acts_as_nested_set_relate_parent!
        acts_as_nested_set_relate_children!

        attr_accessor :skip_before_destroy

        acts_as_nested_set_prevent_assignment_to_reserved_columns!
        acts_as_nested_set_define_callbacks!
      end

      private
      def acts_as_nested_set_define_callbacks!
        # on creation, set automatically lft and rgt to the end of the tree
        before_create  :set_default_left_and_right
        before_save    :store_new_parent
        after_save     :move_to_new_parent, :set_depth!
        before_destroy :destroy_descendants

        define_model_callbacks :move
      end

      def acts_as_nested_set_relate_children!
        has_many_children_options = {
          :class_name => self.base_class.to_s,
          :foreign_key => parent_column_name,
          :primary_key => primary_column_name,
          :inverse_of => (:parent unless acts_as_nested_set_options[:polymorphic]),
        }

        # Add callbacks, if they were supplied.. otherwise, we don't want them.
        [:before_add, :after_add, :before_remove, :after_remove].each do |ar_callback|
          has_many_children_options.update(
            ar_callback => acts_as_nested_set_options[ar_callback]
          ) if acts_as_nested_set_options[ar_callback]
        end

        has_many :children, -> { order(order_column_name => :asc) },
                 has_many_children_options
      end

      def acts_as_nested_set_relate_parent!
        options = {
          :class_name => self.base_class.to_s,
          :foreign_key => parent_column_name,
          :primary_key => primary_column_name,
          :counter_cache => acts_as_nested_set_options[:counter_cache],
          :inverse_of => (:children unless acts_as_nested_set_options[:polymorphic]),
          :polymorphic => acts_as_nested_set_options[:polymorphic],
          :touch => acts_as_nested_set_options[:touch]
        }
        options[:optional] = true if ActiveRecord::VERSION::MAJOR >= 5
        belongs_to :parent, options
      end

      def acts_as_nested_set_default_options
        {
          :parent_column => 'parent_id',
          :primary_column => 'id',
          :left_column => 'lft',
          :right_column => 'rgt',
          :depth_column => 'depth',
          :dependent => :delete_all, # or :destroy
          :polymorphic => false,
          :counter_cache => false,
          :touch => false
        }.freeze
      end

      def acts_as_nested_set_parse_options!(options)
        options = acts_as_nested_set_default_options.merge(options)

        if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
          options[:scope] = "#{options[:scope]}_id".intern
        end

        class_attribute :acts_as_nested_set_options
        self.acts_as_nested_set_options = options
      end

      def acts_as_nested_set_prevent_assignment_to_reserved_columns!
        # no assignment to structure fields
        [left_column_name, right_column_name, depth_column_name].each do |column|
          module_eval <<-"end_eval", __FILE__, __LINE__
            def #{column}=(x)
              raise ActiveRecord::ActiveRecordError, "Unauthorized assignment to #{column}: it's an internal field handled by acts_as_nested_set code, use move_to_* methods instead."
            end
          end_eval
        end
      end
    end
  end
end
