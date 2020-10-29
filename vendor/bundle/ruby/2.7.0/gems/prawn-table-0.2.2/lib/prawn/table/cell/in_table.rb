# encoding: utf-8

# Accessors for using a Cell inside a Table.
#
# Contributed by Brad Ediger.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  class Table

    class Cell

      # This module extends Cell objects when they are used in a table (as
      # opposed to standalone). Its properties apply to cells-in-tables but not
      # cells themselves.
      #
      # @private
      module InTable

        # Row number (0-based).
        #
        attr_accessor :row

        # Column number (0-based).
        #
        attr_accessor :column

      end

    end
  end
end
