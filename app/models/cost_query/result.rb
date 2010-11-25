module CostQuery::Result
  include Report::Result

  class Base < Report::Result::Base
    def inspect
      "<##{self.class}: @fields=#{fields.inspect} @type=#{type.inspect} " \
      "@size=#{size} @count=#{count} @units=#{units} @real_costs=#{real_costs}>"
    end

    def display_costs?
      display_costs > 0
    end
  end

  class DirectResult < Base
    alias fields values

    def has_children?
      false
    end

    def display_costs
      self["display_costs"].to_i
    end

    def count
      self["count"].to_i
    end

    def units
      self["units"].to_d
    end

    def real_costs
      (self["real_costs"] || 0).to_d if display_costs? # FIXME: default value here?
    end

    ##
    # @return [Integer] Number of child results
    def size
      0
    end

    def each
      return enum_for(__method__) unless block_given?
      yield self
    end

    def each_direct_result(cached = false)
      return enum_for(__method__) unless block_given?
      yield self
    end

    def sort!(force = false)
      force
    end
  end

  class WrappedResult < Base
    include Enumerable

    def set_key(index = [])
      values.each { |v| v.set_key index }
      super
    end

    def sort!(force = false)
      return false if @sorted and not force
      values.sort! { |a,b| a.key <=> b.key }
      values.each { |e| e.sort! force }
      @sorted = true
    end

    def depth_of(type)
      super + first.depth_of(type)
    end

    def has_children?
      true
    end

    def count
      sum_for :count
    end

    def display_costs
      (sum_for :display_costs) >= 1 ? 1 : 0
    end

    def units
      sum_for :units
    end

    def real_costs
      sum_for :real_costs if display_costs?
    end

    def sum_for(field)
      @sum_for ||= {}
      @sum_for[field] ||= sum { |v| v.send(field) || 0 }
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

  def self.new(value, fields = {}, type = nil, important_fields = [])
    result = begin
      case value
      when Array then WrappedResult.new value.map { |e| new e, {}, nil, important_fields }
      when Hash  then DirectResult.new value.with_indifferent_access
      when Base  then value
      else raise ArgumentError, "Cannot create Result from #{value.inspect}"
      end
    end
    result.fields.merge! fields
    result.type = type if type
    result.important_fields = important_fields unless result == value
    result
  end
end
