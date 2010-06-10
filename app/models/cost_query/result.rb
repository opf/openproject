require 'big_decimal_patch'

module CostQuery::Result
  class Base
    attr_accessor :parent, :type
    attr_reader :value
    alias values value
    include Enumerable

    def initialize(value)
      @value = value
    end

    def recursive_each_with_level(level = 0, depth_first = true, &block)
      block.call(level, self)
    end

    def recursive_each
      recursive_each_with_level { |level, result| yield result }
    end

    def to_hash
      fields.dup
    end

    def [](key)
      fields[key]
    end

    def grouped_by(fields, type)
      @grouped_by ||= {}
      list = begin
        @grouped_by[fields] ||= begin
          # sub results, have fields
          # i.e. grouping by foo, bar
          data = group_by do |entry|
            # index for group is a hash
            # i.e. { :foo => 10, :bar => 20 } <= this is just the KEY!!!!
            fields.inject({}) { |hash, key| hash.merge key => entry.fields[key] }
          end
          # map group back to array, all fields with same key get grouped into one list
          data.keys.map { |f| CostQuery::Result.new data[f], f, type }
        end
      end
      # create a single result from that list
      CostQuery::Result.new list, {}, type
    end

    def inspect
      "<##{self.class}: @fields=#{fields.inspect} @type=#{type.inspect} " \
      "@size=#{size} @count=#{count} @units=#{units} @real_costs=#{real_costs}>"
    end

    def row?
      type == :row
    end

    def column?
      type == :column
    end

    def direct?
      type == :direct
    end

    def each_row
    end

    def final_row?
      row? and not first.row?
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
      (self["real_costs"] || 0).to_d # FIXME: default value here?
    end

    ##
    # @return [Integer] Number of child results
    def size
      0
    end

    def type
      :direct
    end

    def each
      return enum_for(__method__) unless block_given?
      yield self
    end

    def each_direct_result(cached = false)
      return enum_for(__method__) unless block_given?
      yield self
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

      def each_row
        return enum_for(:each_row) unless block_given?
        if final_row? then yield self
        else each { |c| c.each_row(&Proc.new) }
        end
      end
    end

    def to_a
      values
    end

    def each(&block)
      values.each(&block)
    end

    def each_direct_result(cached = true)
      return enum_for(__method__) unless block_given?
      if @direct_results
        @direct_results.each { |r| yield(r) }
      else
        values.each do |value|
          value.each_direct_result(false) do |result|
            (@direct_results ||= []) << result if cached
            yield result
          end
        end
      end
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

  def self.new(value, fields = {}, type = nil)
    result = begin
      case value
      when Array then WrappedResult.new value.map { |e| new e }
      when Hash  then DirectResult.new value.with_indifferent_access
      when Base  then value
      else raise ArgumentError, "Cannot create Result from #{value.inspect}"
      end
    end
    result.fields.merge! fields
    result.type = type if type
    result
  end
end
