require 'big_decimal_patch'

module CostQuery::Result
  class Base
    attr_accessor :parent, :type
    attr_reader :value
    alias values value

    def initialize(value)
      @value = value
    end

    def recursive_each_with_level(level = 0, depth_first = true, &block)
      block.call(level, self)
    end

    def recursive_each
      recursive_each_with_level { |level, result| yield result }
    end

    def [](key)
      fields[key]
    end

    def grouped_by(fields, type)
      # sub results, have fields
      # i.e. grouping by foo, bar
      data = group_by do |entry|
        # index for group is a hash
        # i.e. { :foo => 10, :bar => 20 } <= this is just the KEY!!!!
        fields.inject({}) { |hash, key| hash.merge key => entry.fields[key] }
      end
      # map group back to array, all fields with same key get grouped into one list
      list = data.keys.map { |f| CostQuery::Result.new data[f], f }
      # create a single result from that list
      CostQuery::Result.new(list).tap { |r| r.type = type }
    end
  end

  class DirectResult < Base
    alias fields values

    def has_children?
      false
    end

    def count
      self["count"].to_i
    end

    def units
      self["units"].to_d
    end

    def real_costs
      self["real_costs"].to_d
    end

    ##
    # @return [Integer] Number of child results
    def size
      0
    end
  end

  class WrappedResult < Base
    include Enumerable

    def has_children?
      true
    end

    def count
      sum_for :count
    end

    def units
      sum_for :units
    end

    def real_costs
      sum_for :real_costs
    end

    def sum_for(field)
      @sum_for ||= {}
      @sum_for[field] ||= inject(0) { |a,v| a + v.send(field) }
    end

    def recursive_each_with_level(level = 0, depth_first = true, &block)
      if depth_first
        super
        each { |c| c.recursive_each_with_level(level + 1, depth_first, &block) }
      else #width-first
        to_evaluate = [self]
        lvl = level
        while !to_evaluate.empty? do
          # evaluate all stored results and find the results we need to evaluate soon
          to_evaluate_soon = []
          to_evaluate.each do |r|
            block.call(lvl,r)
            to_evaluate_soon.concat r.values if r.size > 0
          end
          # take new results to evaluate
          lvl = lvl +1
          to_evaluate = to_evaluate_soon
        end
      end
    end

    def each(&block)
      values.each(&block)
    end

    def fields
      @fields ||= {}.with_indifferent_access
    end

    ##
    # @return [Integer] Number of child results
    def size
      values.size
    end
  end

  def self.new(value, fields = {})
    result = begin
      case value
      when Array then WrappedResult.new value.map { |e| new e }
      when Hash  then DirectResult.new value.with_indifferent_access
      when Base  then value
      else raise ArgumentError, "Cannot create Result from #{value.inspect}"
      end
    end
    result.fields.merge! fields
    result
  end
end
