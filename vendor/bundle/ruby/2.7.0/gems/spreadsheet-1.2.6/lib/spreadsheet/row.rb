require 'spreadsheet/helpers'

module Spreadsheet
  ##
  # The Row class. Encapsulates Cell data and formatting.
  # Since Row is a subclass of Array, you may use all the standard Array methods
  # to manipulate a Row.
  # By convention, Row#at will give you raw values, while Row#[] may be
  # overridden to return enriched data if necessary (see also the Date- and
  # DateTime-handling in Excel::Row#[]
  #
  # Useful Attributes are:
  # #idx::            The 0-based index of this Row in its Worksheet.
  # #formats::        A parallel array containing Formatting information for
  #                   all cells stored in a Row.
  # #default_format:: The default Format used when writing a Cell if no explicit
  #                   Format is stored in #formats for the cell.
  # #height::         The height of this Row in points (defaults to 12).
  class Row < Array
    include Datatypes
    class << self
      def format_updater *keys
        keys.each do |key|
          unless instance_methods.include? "unupdated_#{key}="
            alias_method :"unupdated_#{key}=", :"#{key}="
            define_method "#{key}=" do |value|
              send "unupdated_#{key}=", value
              @worksheet.row_updated @idx, self if @worksheet
              value
            end
          end
        end
      end
      def updater *keys
        keys.each do |key|
          ## Passing blocks to methods defined with define_method is not possible
          #  in Ruby 1.8:
          #  http://groups.google.com/group/ruby-talk-google/msg/778184912b769e5f
          #  use class_eval as suggested by someone else in
          #  http://rubyforge.org/tracker/index.php?func=detail&aid=25732&group_id=678&atid=2677
          class_eval <<-SRC, __FILE__, __LINE__
            def #{key}(*args)
              res = super(*args)
              @worksheet.row_updated @idx, self if @worksheet
              res
            end
          SRC
        end
      end
    end
    attr_reader :formats
    attr_accessor :idx, :height, :worksheet
    boolean :hidden, :collapsed
    enum :outline_level, 0, Integer
    updater :[]=, :clear, :concat, :delete, :delete_if, :fill, :insert, :map!,
            :pop, :push, :reject!, :replace, :reverse!, :shift, :slice!,
            :sort!, :uniq!, :unshift
    format_updater :collapsed, :height, :hidden, :outline_level
    def initialize worksheet, idx, cells=[]
      @default_format = nil
      @worksheet = worksheet
      @idx = idx
      super cells
      @formats = []
      @height = 12.1
    end
    ##
    # The default Format of this Row, if you have set one.
    # Returns the Worksheet's default or the Workbook's default Format otherwise.
    def default_format
      @default_format || @worksheet.default_format || @workbook.default_format
    end
    ##
    # Set the default Format used when writing a Cell if no explicit Format is
    # stored for the cell.
    def default_format= format
      @worksheet.add_format format if @worksheet
      @default_format = format
    end
    format_updater :default_format
    ##
    # #first_used the 0-based index of the first non-blank Cell.
    def first_used
      [ index_of_first(self), index_of_first(@formats) ].compact.min
    end
    ##
    # The Format for the Cell at _idx_ (0-based), or the first valid Format in
    # Row#default_format, Column#default_format and Worksheet#default_format.
    def format idx
      @formats[idx] || @default_format \
        || @worksheet.column(idx).default_format if @worksheet
    end
    ##
    # Returns a copy of self with nil-values appended for empty cells that have
    # an associated Format.
    # This is primarily a helper-function for the writer classes.
    def formatted
      copy = dup
      Helpers.rcompact(@formats)
      if copy.length < @formats.size
        copy.concat Array.new(@formats.size - copy.length)
      end
      copy
    end
    ##
    # Same as Row#size, but takes into account formatted empty cells
    def formatted_size
      Helpers.rcompact(@formats)
      sz = size
      fs = @formats.size
      fs > sz ? fs : sz
    end
    ##
    # #first_unused (really last used + 1) - the 0-based index of the first of
    # all remaining contiguous blank Cells.
    alias :first_unused :formatted_size
    def inspect
      variables = instance_variables.collect do |name|
        "%s=%s" % [name, instance_variable_get(name)]
      end.join(' ')
      sprintf "#<%s:0x%014x %s %s>", self.class, object_id, variables, super
    end
    ##
    # Set the Format for the Cell at _idx_ (0-based).
    def set_format idx, fmt
      @formats[idx] = fmt
      @worksheet.add_format fmt
      @worksheet.row_updated @idx, self if @worksheet
      fmt
    end

    def update_format(idx, opts = {})
      if @formats[idx]
        @formats[idx].update_format(opts)
      else
        fmt = default_format.clone
        fmt.font = fmt.font.clone
        @formats[idx] = fmt.update_format(opts)
      end
      @worksheet.add_format @formats[idx]
      @worksheet.row_updated @idx, self if @worksheet
    end

    private
    def index_of_first ary # :nodoc:
      if first = ary.find do |elm| !elm.nil? end
        ary.index first
      end
    end
  end
end
