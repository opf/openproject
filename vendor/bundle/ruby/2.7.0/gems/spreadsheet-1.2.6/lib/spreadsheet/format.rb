# encoding: utf-8
require 'spreadsheet/datatypes'
require 'spreadsheet/encodings'
require 'spreadsheet/font'

module Spreadsheet
  ##
  # Formatting data
  class Format
    include Spreadsheet::Datatypes
    include Spreadsheet::Encodings
    ##
    # You can set the following boolean attributes:
    # #cross_down::       Draws a Line from the top-left to the bottom-right
    #                     corner of a cell.
    # #cross_up::         Draws a Line from the bottom-left to the top-right
    #                     corner of a cell.
    # #hidden::           The cell is hidden.
    # #locked::           The cell is locked.
    # #merge_range::      The cell is in a merged range.
    # #shrink::           Shrink the contents to fit the cell.
    # #text_justlast::    Force the last line of a cell to be justified. This
    #                     probably makes sense if horizontal_align = :justify
    # #left::             Apply a border style to the left of the cell.
    # #right::            Apply a border style to the right of the cell.
    # #top::              Apply a border style at the top of the cell.
    # #bottom::           Apply a border style at the bottom of the cell.
    # #rotation_stacked:: Characters in the cell are stacked on top of each
    #                     other. Excel will ignore other rotation values if
    #                     this is set.
    boolean :cross_down, :cross_up, :hidden, :locked,
            :merge_range, :shrink, :text_justlast, :text_wrap,
						:rotation_stacked
    ##
    # Border line styles
    # Valid values: :none, :thin, :medium, :dashed, :dotted, :thick, 
		#               :double, :hair, :medium_dashed, :thin_dash_dotted,
		#               :medium_dash_dotted, :thin_dash_dot_dotted,
		#               :medium_dash_dot_dotted, :slanted_medium_dash_dotted
    # Default:			:none
		styles = [ :thin, :medium, :dashed, :dotted, :thick, 
							 :double, :hair, :medium_dashed, :thin_dash_dotted,
							 :medium_dash_dotted, :thin_dash_dot_dotted,
							 :medium_dash_dot_dotted, :slanted_medium_dash_dotted ]
		enum :left,		:none, *styles
		enum :right,	:none, *styles
		enum :top,		:none, *styles
		enum :bottom,	:none, *styles

    ##
    # Color attributes
    colors  :bottom_color, :top_color, :left_color, :right_color,
            :pattern_fg_color, :pattern_bg_color,
            :diagonal_color
    ##
    # Text direction
    # Valid values: :context, :left_to_right, :right_to_left
    # Default:      :context
    enum :text_direction, :context, :left_to_right, :right_to_left,
         :left_to_right => [:ltr, :l2r],
         :right_to_left => [:rtl, :r2l]
    alias :reading_order  :text_direction
    alias :reading_order= :text_direction=
    ##
    # Indentation level
    enum :indent_level, 0, Integer
    alias :indent  :indent_level
    alias :indent= :indent_level=
    ##
    # Horizontal alignment
    # Valid values: :default, :left, :center, :right, :fill, :justify, :merge,
    #               :distributed
    # Default:      :default
    enum :horizontal_align, :default, :left, :center, :right, :fill, :justify,
                            :merge, :distributed,
         :center      => :centre,
         :merge       => [ :center_across, :centre_across ],
         :distributed => :equal_space
    ##
    # Vertical alignment
    # Valid values: :bottom, :top, :middle, :justify, :distributed
    # Default:      :bottom
    enum :vertical_align, :bottom, :top, :middle, :justify, :distributed,
         :distributed => [:vdistributed, :vequal_space, :equal_space],
         :justify     => :vjustify,
         :middle      => [:vcenter, :vcentre, :center, :centre]
    attr_accessor :font, :number_format, :name, :pattern, :used_merge
    ##
    # Text rotation
    attr_reader :rotation
    def initialize opts={}
      @font             = Font.new client("Arial", 'UTF-8'), :family => :swiss
      @number_format    = client 'GENERAL', 'UTF-8'
      @rotation         = 0
      @pattern          = 0
      @bottom_color     = :black
      @top_color        = :black
      @left_color       = :black
      @right_color      = :black
      @diagonal_color   = :black
      @pattern_fg_color = :border
      @pattern_bg_color = :pattern_bg
      @regexes = {
        :date         => Regexp.new(client("[YMD]|d{2}|m{3}|y{2}", 'UTF-8')),
        :date_or_time => Regexp.new(client("[hmsYMD]", 'UTF-8')),
        :datetime     => Regexp.new(client("([YMD].*[HS])|([HS].*[YMD])", 'UTF-8')),
        :time         => Regexp.new(client("[hms]", 'UTF-8')),
        :number       => Regexp.new(client("([\#]|0+)", 'UTF-8')),
        :locale       => Regexp.new(client(/\A\[\$\-\S+\]/.to_s, 'UTF-8')),
      }

      # Temp code to prevent merged formats in non-merged cells.
      @used_merge = 0
      update_format(opts)

      yield self if block_given?
    end

    def update_format(opts = {})
      opts.each do |attribute, value|
        writer = "#{attribute}="
        @font.respond_to?(writer) ? @font.send(writer,value) : self.send(writer, value) 
      end
      self
    end

    ##
    # Combined method for both horizontal and vertical alignment. Sets the
    # first valid value (e.g. Format#align = :justify only sets the horizontal
    # alignment. Use one of the aliases prefixed with :v if you need to
    # disambiguate.)
    #
    # This is essentially a backward-compatibility method and may be removed at
    # some point in the future.
    def align= location
      self.horizontal_align = location
    rescue ArgumentError
      self.vertical_align = location rescue ArgumentError
    end
    ##
    # Returns an Array containing the line styles of the four borders:
    # bottom, top, right, left
    def border
      [bottom, top, right, left]
    end
    ##
    # Set same line style on all four borders at once (left, right, top, bottom)
    def border=(style)
      [:bottom=, :top=, :right=, :left=].each do |writer| send writer, style end
    end
    ##
    # Returns an Array containing the colors of the four borders:
    # bottom, top, right, left
    def border_color
      [@bottom_color,@top_color,@right_color,@left_color]
    end
    ##
    # Set all four border colors to _color_ (left, right, top, bottom)
    def border_color=(color)
      [:bottom_color=, :top_color=, :right_color=, :left_color=].each do |writer|
        send writer, color end
    end
    ##
    # Set the Text rotation
    # Valid values: Integers from -90 to 90,
    # or :stacked (sets #rotation_stacked to true)
    def rotation=(rot)
      if rot.to_s.downcase == 'stacked'
        @rotation_stacked = true
        @rotation = 0
      elsif rot.kind_of?(Integer)
        @rotation_stacked = false
        @rotation = rot % 360
      else
        raise TypeError, "rotation value must be an Integer or the String 'stacked'"
      end
    end
    ##
    # Backward compatibility method. May disappear at some point in the future.
    def center_across!
      self.horizontal_align = :merge
    end
    alias :merge! :center_across!
    ##
    # Is the cell formatted as a Date?
    def date?
      !number? && matches_format?(:date)
    end
    ##
    # Is the cell formatted as a Date or Time?
    def date_or_time?
      !number? && matches_format?(:date_or_time)
    end
    ##
    # Is the cell formatted as a DateTime?
    def datetime?
      !number? && matches_format?(:datetime)
    end
    ##
    # Is the cell formatted as a Time?
    def time?
      !number? && matches_format?(:time)
    end
    ##
    # Is the cell formatted as a number?
    def number?
      matches_format?(:number)
    end
    ##
    # Does the cell match a particular preset format?
    def matches_format?(name)
      # Excel number formats may optionally include a locale identifier like this:
      #   [$-409]
      format = @number_format.to_s.sub(@regexes[:locale], '')
      !!@regexes[name].match(format)
    end
  end
end
