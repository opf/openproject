module Airbrake
  # FilterChain represents an ordered array of filters.
  #
  # A filter is an object that responds to <b>#call</b> (typically a Proc or a
  # class that implements the call method). The <b>#call</b> method must accept
  # exactly one argument: an object to be filtered.
  #
  # When you add a new filter to the chain, it gets inserted according to its
  # <b>weight</b>. Smaller weight means the filter will be somewhere in the
  # beginning of the array. Larger - in the end. If a filter doesn't implement
  # weight, the chain assumes it's equal to 0.
  #
  # @example
  #   class MyFilter
  #     attr_reader :weight
  #
  #     def initialize
  #       @weight = 1
  #     end
  #
  #     def call(obj)
  #       puts 'Filtering...'
  #       obj[:data] = '[Filtered]'
  #     end
  #   end
  #
  #   filter_chain = FilterChain.new
  #   filter_chain.add_filter(MyFilter)
  #
  #   filter_chain.refine(obj)
  #   #=> Filtering...
  #
  # @see Airbrake.add_filter
  # @api private
  # @since v1.0.0
  class FilterChain
    # @return [Integer]
    DEFAULT_WEIGHT = 0

    def initialize
      @filters = []
    end

    # Adds a filter to the filter chain. Sorts filters by weight.
    #
    # @param [#call] filter The filter object (proc, class, module, etc)
    # @return [void]
    def add_filter(filter)
      @filters = (@filters << filter).sort_by do |f|
        f.respond_to?(:weight) ? f.weight : DEFAULT_WEIGHT
      end.reverse!
    end

    # Deletes a filter from the the filter chain.
    #
    # @param [Class] filter_class The class of the filter you want to delete
    # @return [void]
    # @since v3.1.0
    def delete_filter(filter_class)
      index = @filters.index { |f| f.class.name == filter_class.name }
      @filters.delete_at(index) if index
    end

    # Applies all the filters in the filter chain to the given notice. Does not
    # filter ignored notices.
    #
    # @param [Airbrake::Notice] notice The notice to be filtered
    # @return [void]
    # @todo Make it work with anything, not only notices
    def refine(notice)
      @filters.each do |filter|
        break if notice.ignored?

        filter.call(notice)
      end
    end

    # @return [String] customized inspect to lessen the amount of clutter
    def inspect
      filter_classes.to_s
    end

    # @return [String] {#inspect} for PrettyPrint
    def pretty_print(q)
      q.text('[')

      # Make nesting of the first element consistent on JRuby and MRI.
      q.nest(2) { q.breakable } if @filters.any?

      q.nest(2) do
        q.seplist(@filters) { |f| q.pp(f.class) }
      end
      q.text(']')
    end

    # @param [Class] filter_class
    # @return [Boolean] true if the current chain has an instance of the given
    #   class, false otherwise
    # @since v4.14.0
    def includes?(filter_class)
      filter_classes.include?(filter_class)
    end

    private

    def filter_classes
      @filters.map(&:class)
    end
  end
end
