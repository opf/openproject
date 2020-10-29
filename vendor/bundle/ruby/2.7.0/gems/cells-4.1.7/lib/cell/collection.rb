module Cell
  class Collection
    def initialize(ary, options, cell_class)
      options.delete(:collection)
      set_deprecated_options(options) # TODO: remove in 5.0.

      @ary        = ary
      @options    = options    # these options are "final" and will be identical for all collection cells.
      @cell_class = cell_class
    end

    def set_deprecated_options(options) # TODO: remove in 5.0.
      self.method = options.delete(:method)                   if options.include?(:method)
      self.collection_join = options.delete(:collection_join) if options.include?(:collection_join)
    end

    module Call
      def call(state=:show)
        join(collection_join) { |cell, i| cell.(method || state) }
      end

    end
    include Call

    def to_s
      call
    end

    # Iterate collection and build a cell for each item.
    # The passed block receives that cell and the index.
    # Its return value is captured and joined.
    def join(separator="", &block)
      @ary.each_with_index.collect do |model, i|
        cell = @cell_class.build(model, @options)
        block_given? ? yield(cell, i) : cell
      end.join(separator)
    end

    module Layout
      def call(*) # WARNING: THIS IS NOT FINAL API.
        layout = @options.delete(:layout) # we could also override #initialize and that there?

        content = super # DISCUSS: that could come in via the pipeline argument.
        ViewModel::Layout::External::Render.(content, @ary, layout, @options)
      end
    end
    include Layout

    # TODO: remove in 5.0.
    private
    attr_accessor :collection_join, :method

    extend Gem::Deprecate
    deprecate :method=, "`call(method)` as documented here: http://trailblazer.to/gems/cells/api.html#collection", 2016, 7
    deprecate :collection_join=, "`join(\"<br>\")` as documented here: http://trailblazer.to/gems/cells/api.html#collection", 2016, 7
  end
end

# Collection#call
# |> Header#call
# |> Layout#call
