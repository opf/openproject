require 'acts_as_tree/version'

module ActsAsTree

  if defined? Rails::Railtie
    require 'acts_as_tree/railtie'
  elsif defined? Rails::Initializer
    raise "acts_as_tree 1.0 is not compatible with Rails 2.3 or older"
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  # Specify this +acts_as+ extension if you want to model a tree structure
  # by providing a parent association and a children association. This
  # requires that you have a foreign key column, which by default is called
  # +parent_id+.
  #
  #   class Category < ActiveRecord::Base
  #     include ActsAsTree
  #
  #     acts_as_tree :order => "name"
  #   end
  #
  #   Example:
  #   root
  #    \_ child1
  #         \_ subchild1
  #         \_ subchild2
  #
  #   root      = Category.create("name" => "root")
  #   child1    = root.children.create("name" => "child1")
  #   subchild1 = child1.children.create("name" => "subchild1")
  #
  #   root.parent   # => nil
  #   child1.parent # => root
  #   root.children # => [child1]
  #   root.children.first.children.first # => subchild1
  #
  # In addition to the parent and children associations, the following
  # instance methods are added to the class after calling
  # <tt>acts_as_tree</tt>:
  # * <tt>siblings</tt> - Returns all the children of the parent, excluding
  #                       the current node (<tt>[subchild2]</tt> when called
  #                       on <tt>subchild1</tt>)
  # * <tt>self_and_siblings</tt> - Returns all the children of the parent,
  #                                including the current node (<tt>[subchild1, subchild2]</tt>
  #                                when called on <tt>subchild1</tt>)
  # * <tt>ancestors</tt> - Returns all the ancestors of the current node
  #                        (<tt>[child1, root]</tt> when called on <tt>subchild2</tt>)
  # * <tt>root</tt> - Returns the root of the current node (<tt>root</tt>
  #                   when called on <tt>subchild2</tt>)
  module ClassMethods
    # Configuration options are:
    #
    # * <tt>primary_key</tt> - specifies the column name for relations
    #                          (default: +id+)
    # * <tt>foreign_key</tt> - specifies the column name to use for tracking
    #                          of the tree (default: +parent_id+)
    # * <tt>order</tt> - makes it possible to sort the children according to
    #                    this SQL snippet.
    # * <tt>counter_cache</tt> - keeps a count in a +children_count+ column
    #                            if set to +true+ (default: +false+). Specify
    #                            a custom column by passing a symbol or string.
    def acts_as_tree(options = {})
      configuration = {
        primary_key:   "id",
        foreign_key:   "parent_id",
        order:         nil,
        counter_cache: nil,
        dependent:     :destroy,
        touch:         false
      }

      configuration.update(options) if options.is_a?(Hash)

      if configuration[:counter_cache] == true
        configuration[:counter_cache] = :children_count
      end

      if ActiveRecord::VERSION::MAJOR >= 5
        belongs_to :parent,
          class_name:    name,
          primary_key:   configuration[:primary_key],
          foreign_key:   configuration[:foreign_key],
          counter_cache: configuration[:counter_cache],
          touch:         configuration[:touch],
          inverse_of:    :children,
          optional:      true
      else
        belongs_to :parent,
          class_name:    name,
          primary_key:   configuration[:primary_key],
          foreign_key:   configuration[:foreign_key],
          counter_cache: configuration[:counter_cache],
          touch:         configuration[:touch],
          inverse_of:    :children
      end

      if ActiveRecord::VERSION::MAJOR >= 4
        has_many :children, lambda { order configuration[:order] },
          class_name:  name,
          primary_key: configuration[:primary_key],
          foreign_key: configuration[:foreign_key],
          dependent:   configuration[:dependent],
          inverse_of:  :parent
      else
        has_many :children,
          class_name:  name,
          primary_key: configuration[:primary_key],
          foreign_key: configuration[:foreign_key],
          order:       configuration[:order],
          dependent:   configuration[:dependent],
          inverse_of:  :parent
      end

      include ActsAsTree::InstanceMethods

      define_singleton_method :default_tree_order do
        order(configuration[:order])
      end

      define_singleton_method :root do
        self.roots.first
      end

      define_singleton_method :roots do
        where(configuration[:foreign_key] => nil).default_tree_order
      end

      # Returns a hash of all nodes grouped by their level in the tree structure.
      #
      # Class.generations # => { 0=> [root1, root2], 1=> [root1child1, root1child2, root2child1, root2child2] }
      def self.generations
        all.group_by{ |node| node.tree_level }
      end


      if configuration[:counter_cache]
        after_update :update_parents_counter_cache

        def children_counter_cache_column
          reflect_on_association(:parent).counter_cache_column
        end

        def leaves
          where(children_counter_cache_column => 0).default_tree_order
        end

      else
        # Fallback to less efficient ways to find leaves.
        class_eval <<-EOV
          def self.leaves
            internal_ids = select(:#{configuration[:foreign_key]}).where(arel_table[:#{configuration[:foreign_key]}].not_eq(nil))
            where("\#{connection.quote_column_name('#{configuration[:primary_key]}')} NOT IN (\#{internal_ids.to_sql})").default_tree_order
          end
        EOV
      end
    end

  end

  module TreeView
    # show records in a tree view
    # Example:
    # root
    #  |_ child1
    #  |    |_ subchild1
    #  |    |_ subchild2
    #  |_ child2
    #       |_ subchild3
    #       |_ subchild4
    #
    def tree_view(label_method = :to_s,  node = nil, level = -1)
      if node.nil?
        puts "root"
        nodes = roots
      else
        label = "|_ #{node.send(label_method)}"
        if level == 0
          puts " #{label}"
        else
          puts " |#{"    "*level}#{label}"
        end
        nodes = node.children
      end
      nodes.each do |child|
        tree_view(label_method, child, level+1)
      end
    end

  end

  module TreeWalker
    # Traverse the tree and call a block with the current node and current
    # depth-level.
    #
    # options:
    #   algorithm:
    #     :dfs for depth-first search (default)
    #     :bfs for breadth-first search
    #   where: AR where statement to filter certain nodes
    #
    # The given block sets two parameters:
    #   first: The current node
    #   second: The current depth-level within the tree
    #
    # Example of acts_as_tree for model Page (ERB view):
    # <% Page.walk_tree do |page, level| %>
    #   <%= link_to "#{' '*level}#{page.name}", page_path(page) %><br />
    # <% end %>
    #
    # There is also a walk_tree instance method that starts walking from
    # the node it is called on.
    #
    def walk_tree(options = {}, &block)
      algorithm = options.fetch :algorithm, :dfs
      where = options.fetch :where, {}
      send("walk_tree_#{algorithm}", where, &block)
    end

    def self.extended(mod)
      mod.class_eval do
        def walk_tree(options = {}, &block)
          algorithm = options.fetch :algorithm, :dfs
          where = options.fetch :where, {}
          self.class.send("walk_tree_#{algorithm}", where, self, &block)
        end
      end
    end

    private

    def walk_tree_bfs(where = {}, node = nil, level = -1, &block)
      nodes = (node.nil? ? roots : node.children).where(where)
      nodes.each { |child| yield(child, level + 1) }
      nodes.each { |child| walk_tree_bfs where, child, level + 1, &block }
    end

    def walk_tree_dfs(where = {}, node = nil, level = -1, &block)
      yield(node, level) unless level == -1
      nodes = (node.nil? ? roots : node.children).where(where)
      nodes.each { |child| walk_tree_dfs where, child, level + 1, &block }
    end

  end

  module InstanceMethods
    # Returns list of ancestors, starting from parent until root.
    #
    #   subchild1.ancestors # => [child1, root]
    def ancestors
      node, nodes = self, []
      nodes << node = node.parent while node.parent
      nodes
    end

    # Returns list of descendants, starting from current node, not including current node.
    #
    #   root.descendants # => [child1, child2, subchild1, subchild2, subchild3, subchild4]
    def descendants
      children.each_with_object(children.to_a) {|child, arr|
        arr.concat child.descendants
      }.uniq
    end

    # Returns list of descendants, starting from current node, including current node.
    #
    #   root.self_and_descendants # => [root, child1, child2, subchild1, subchild2, subchild3, subchild4]
    def self_and_descendants
      [self] + descendants
    end

    # Returns the root node of the tree.
    def root
      node = self
      node = node.parent while node.parent
      node
    end

    # Returns all siblings of the current node.
    #
    #   subchild1.siblings # => [subchild2]
    def siblings
      self_and_siblings - [self]
    end

    # Returns all siblings and a reference to the current node.
    #
    #   subchild1.self_and_siblings # => [subchild1, subchild2]
    def self_and_siblings
      parent ? parent.children : self.class.roots
    end

    # Returns all the nodes at the same level in the tree as the current node.
    #
    #  root1child1.generation # => [root1child2, root2child1, root2child2]
    def generation
      self_and_generation - [self]
    end

    # Returns a reference to the current node and all the nodes at the same level as it in the tree.
    #
    #  root1child1.self_and_generation # => [root1child1, root1child2, root2child1, root2child2]
    def self_and_generation
      self.class.select {|node| node.tree_level == self.tree_level }
    end

    # Returns the level (depth) of the current node 
    #
    #  root1child1.tree_level # => 1
    def tree_level
      self.ancestors.size
    end

    # Returns the level (depth) of the current node unless level is a column on the node. 
    # Allows backwards compatibility with older versions of the gem.  
    # Allows integration with apps using level as a column name.
    #
    #  root1child1.level # => 1
    def level
      if self.class.column_names.include?('level')
        super
      else
        tree_level
      end
    end

    # Returns children (without subchildren) and current node itself.
    #
    #   root.self_and_children # => [root, child1]
    def self_and_children
      [self] + self.children
    end

    # Returns ancestors and current node itself.
    #
    #   subchild1.self_and_ancestors # => [subchild1, child1, root]
    def self_and_ancestors
      [self] + self.ancestors
    end

    # Returns true if node has no parent, false otherwise
    #
    #   subchild1.root? # => false
    #   root.root?      # => true
    def root?
      parent.nil?
    end

    # Returns true if node has no children, false otherwise
    #
    #   subchild1.leaf? # => true
    #   child1.leaf?    # => false
    def leaf?
      children.size.zero?
    end

    private

    if ActiveRecord::VERSION::MAJOR > 5 || ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR >= 2
      def update_parents_counter_cache
      end
    elsif ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR == 1
      def update_parents_counter_cache
        counter_cache_column = self.class.children_counter_cache_column

        if saved_change_to_parent_id?
          self.class.decrement_counter(counter_cache_column, parent_id_before_last_save)
          self.class.increment_counter(counter_cache_column, parent_id)
        end
      end
    else
      def update_parents_counter_cache
        counter_cache_column = self.class.children_counter_cache_column

        if parent_id_changed?
          self.class.decrement_counter(counter_cache_column, parent_id_was)
          self.class.increment_counter(counter_cache_column, parent_id)
        end
      end
    end
  end
end

# Deprecating the following code in the future.
require 'acts_as_tree/active_record/acts/tree'
