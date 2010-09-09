# This is no actual runnable ruby code.
# It merely presents our ideas to refactor the CostQuery model

class Operator
  def self.new(name, &block)
    all[name] ||= super
  end
  def self.all
    @all ||= {}
  end
  def self.find(name)
    Operator.all[name] or raise "Operator not defined"
  end
  def initialize(name, &block)
    eigenclass.class_eval(&block)
  end
  def eigenclass
    class << self
      self
    end
  end
end

Operator.new(:=) do
  # Example to define and register an operator
  def sql_where()
  end
end





class Filter
  def self.new
    # this class is abstract. instances are only allowed from child classes
    raise "#{self.name} is an abstract class" if self == Filter
    super
  end

  def self.column(column = nil)
    @column = column if column
    @column
  end
  def self.operators(*operators)
    # Does it make sense to just store the names here and perform Operator.find
    # if needed?

    operators.each do |o|
      o = Operator.find(o) unless o.is_a? Operator
      @operators << o
    end
  end

  # Store the default operator
  # NOTE: this should be implemented explictly
  cattr_accessor :default_operator

  def self.from_hash
    # deserialize a new filter object from a hash
    # NOTE: this might also be used to create a filter object from browse
    # parameters

    # ...
  end

  def to_hash
    # serialize self to a hash suitable for later deserialization with
    # Filter.from_hash
    # This can be used to save the filter to a database or to create a part of
    # the query string in the view

    # ...
  end

  attr_accessor :operator

  def sql_select
    # returns the default select part of a query
    # This might be overwritten in child classes
    # NOTE: this might be changed to an item of the :include array of an ActiveRecord::Base.find

    "#{model.table_name}.#{db_field} as #{self.class.name.underscore}"
  end


  def sql_where()
    # returns the default where part of a query
    # This might be overwritten in child classes to provide special logic besides
    # standard operators.
    #
    # NOTE: This should be suitable to be used in :conditions in an ActiveRecord::Base.find

    Operator.find(operator).sql_where()
  end

  # self.model
  # self.db_field
  # available_values(user)


  def sql_joins(otiginal_table)
    # returns an array of all needed joins
    # original_table is thw name of the original table of the join (e.g. time_entries or cost_entries)
    # NOTE: this might be used to generate :include items
    ["JOIN issues ON #{table}.issue_id = issues.id", "JOIN users on #{table}.user_id = user.id"]
  end

end

class FooFilter < FilterColumn
  # This is an example definition of a folter column class

  operators :=, :!=, :<=, :>=, :<&>
  column :foo
  model :issues

  def sql_where(table)
    if operator == "<&>"
      # special logic
    else
      super
    end
  end
end

# another example which uses another layer ofg inheritance to provide filter types
class SimpleListFilter << FilterColumn
  operators :=, :!=
end

class UserFilter < SimpleListFilter
  column :user_id
end



# e.g. in CostQuery
def create_join_statement(table)
  all_filters.map { |f| f.join_condition(table) }.flatten.uniq
end


# The following two classes represent the result of a group-by operation

class ReportGroupOfGroups < Array
  def sum
    @sum ||= inject(0) { |e| e.sum }
  end

  def count
    @count ||= inject(0) { |e| e.cont }
  end

  def has_children?
    true
  end

  def drill_down_filter
    # this uses the parent pointer of the GroupBy instance
    # ...
  end

  def recursive_each(level = 0, &block)
    block.call(level, self)
    each { |child| child.recursive_each(level + 1, &block) }
  end
end

class ReportGroup
  def initialize(hash_from_database)
    @data = hash_from_database
  end
  def count
    @data["count"]
  end
  def has_children?
    false
  end
  def recursive_each(level = 0, &block)
    block.call(level, self)
  end
end

class GroupBy
  # This provides the stared functionality of a group-by columnh

  module BasicGroupBy
    # Module to be used, if this instance is the group-by with the finest
    # granularity (or the single one)
    def filters
      [filter_for_group, @based_on]
    end
    def results(columns = nil)
      columns << my_column
      "SELECT count() FROM #{@based_on.sql_statement} GROUP_BY #{columns.uniq.join(", ")}"
    end
  end
  module GroupOfGroupBy
    # Module to use for higher granularity
    def results(columns = nil)
      group @based_on.results(columns)
    end
    def filters()
      [filter_for_group] << @based_on.filters
    end
  end

  attr_accessor :parent

  def initialize(based_on)
    # NOTE: based_on should actually be an array of filters
    if based_on.is_a? Filter
      extend BasicGroupBy
    elsif based_on.is_a? GroupBy
      extend GroupOfGroupBy
      # provide a parent pointer of the tree
      based_on.parent = self
    end
  end

  def filter_for_group
    # create filter from group by from drill down
    # NOTE: this does not make sense here (???)
    # ...
  end

end

class GroupByName < GroupBy

  def results(columns)
    columns.delete :dont_like
    super
  end
end

# Example to define a group by hierarchy
filter = Filter.new
erste_verschachtellung = GroupByName.new(filter)
zweite_verschachtellung = GroupByIssue.new(erste_verschachtellung)

# execute the call and get the results (as an instance of ReportGroupOfGroups or ReportGroup)
zweite_verschachtellung.results.sum

# get the respective filter for the drill down into this group
zweite_verschachtellung.results.first.drill_down_filter

# display all groups in a tree-like view
zweite_verschachtellung.recursive_each do |level, group|
  puts ">"*level, group.count, group.sum
end