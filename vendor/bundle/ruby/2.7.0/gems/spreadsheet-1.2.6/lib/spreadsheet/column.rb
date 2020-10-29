require 'spreadsheet/datatypes'

module Spreadsheet
  ##
  # The Column class. Encapsulates column-formatting and width, and provides a
  # means to iterate over all cells in a column.
  #
  # Useful Attributes:
  # #width::          The width in characters (in respect to the '0' character
  #                   of the Worksheet's default Font). Float values are
  #                   permitted, for Excel the available Precision is at 1/256
  #                   characters.
  # #default_format:: The default Format for cells in this column (applied if
  #                   there is no explicit Cell Format and no default Row format
  #                   for the Cell).
  # #hidden::         The Column is hidden.
  # #collapsed::      The Column is collapsed.
  # #outline_level::  Outline level of the column.
  class Column
    class << self
      def updater *keys
        keys.each do |key|
          unless instance_methods.include? "unupdated_#{key}="
            alias_method :"unupdated_#{key}=", :"#{key}="
            define_method "#{key}=" do |value|
              send "unupdated_#{key}=", value
              @worksheet.column_updated @idx, self if @worksheet
              value
            end
          end
        end
      end
    end
    include Datatypes
    include Enumerable
    attr_accessor :width, :worksheet
    attr_reader :default_format, :idx
    boolean :hidden, :collapsed
    enum :outline_level, 0, Integer
    updater :collapsed, :hidden, :outline_level, :width
    def initialize idx, format, opts={}
      @worksheet = nil
      @idx = idx
      opts[:width] ||= 10
      opts.each do |key, value|
        self.send "#{key}=", value
      end
      self.default_format = format
    end
    ##
    # Set the default Format for Cells in this Column.
    def default_format= format
      @worksheet.add_format format if @worksheet
      @default_format = format
      @worksheet.column_updated @idx, self if @worksheet
      format
    end
    ##
    # Iterate over all cells in this column.
    def each
      @worksheet.each do |row|
        yield row[idx]
      end
    end
    def == other # :nodoc:
      other.is_a?(Column) && default_format == other.default_format \
        && width == other.width && hidden == other.hidden \
        && collapsed == other.collapsed && outline_level == other.outline_level
    end
  end
end
