# encoding: utf-8

module Prawn
  class Table
    # @private
    class ColumnWidthCalculator
      def initialize(cells)
        @cells = cells

        @widths_by_column        = Hash.new(0)
        @rows_with_a_span_dummy  = Hash.new(false)

        #calculate for each row if it includes a Cell:SpanDummy
        @cells.each do |cell|
          @rows_with_a_span_dummy[cell.row] = true if cell.is_a?(Cell::SpanDummy)
        end
      end

      # does this row include a Cell:SpanDummy?
      #
      # @param row - the row that should be checked for Cell:SpanDummy elements
      #
      def has_a_span_dummy?(row)
        @rows_with_a_span_dummy[row]
      end

      # helper method
      # column widths are stored in the values array
      # a cell may span cells whose value is only partly given
      # this function handles this special case
      #
      # @param values - The columns widths calculated up until now
      # @param cell - The current cell
      # @param index - The current column
      # @param meth - Meth (min/max); used to calculate values to be filled
      #
      def fill_values_if_needed(values, cell, index, meth)
        #have all spanned indices been filled with a value?
        #e.g. values[0], values[1] and values[2] don't return nil given a index of 0 and a colspan of 3
        number_of_nil_values = 0
        cell.colspan.times do |i|
          number_of_nil_values += 1 if values[index+i].nil?
        end

        #nothing to do? because
        #a) all values are filled
        return values if number_of_nil_values == 0
        #b) no values are filled
        return values if number_of_nil_values == cell.colspan
        #c) I am not sure why this line is needed FIXXME
        #some test cases manage to this line even though there is no dummy cell in the row
        #I'm not sure if this is a sign for a further underlying bug.
        return values unless has_a_span_dummy?(cell.row)
        #fill up the values array

        #calculate the new sum
        new_sum = cell.send(meth) * cell.colspan
        #substract any calculated values
        cell.colspan.times do |i|
          new_sum -= values[index+i] unless values[index+i].nil?
        end

        #calculate value for the remaining - not yet filled - cells.
        new_value = new_sum.to_f / number_of_nil_values
        #fill the not yet filled cells
        cell.colspan.times do |i|
          values[index+i] = new_value if values[index+i].nil?
        end
        return values
      end

      def natural_widths
        #calculate natural column width for all rows that do not include a span dummy
        @cells.each do |cell|
          unless has_a_span_dummy?(cell.row)
            @widths_by_column[cell.column] =
              [@widths_by_column[cell.column], cell.width.to_f].max
          end
        end

        #integrate natural column widths for all rows that do include a span dummy
        @cells.each do |cell|
          next unless has_a_span_dummy?(cell.row)
          #the width of a SpanDummy cell will be calculated by the "mother" cell
          next if cell.is_a?(Cell::SpanDummy)

          if cell.colspan == 1
            @widths_by_column[cell.column] =
              [@widths_by_column[cell.column], cell.width.to_f].max
          else
            #calculate the current with of all cells that will be spanned by the current cell
            current_width_of_spanned_cells =
              @widths_by_column.to_a[cell.column..(cell.column + cell.colspan - 1)]
                               .collect{|key, value| value}.inject(0, :+)

            #update the Hash only if the new with is at least equal to the old one
            #due to arithmetic errors we need to ignore a small difference in the new and the old sum
            #the same had to be done in the column_widht_calculator#natural_width
            update_hash = ((cell.width.to_f - current_width_of_spanned_cells) >
                           Prawn::FLOAT_PRECISION)

            if update_hash
              # Split the width of colspanned cells evenly by columns
              width_per_column = cell.width.to_f / cell.colspan
              # Update the Hash
              cell.colspan.times do |i|
                @widths_by_column[cell.column + i] = width_per_column
              end
            end
          end
        end

        @widths_by_column.sort_by { |col, _| col }.map { |_, w| w }
      end

      # get column widths (either min or max depending on meth)
      # used in cells.rb
      #
      # @param row_or_column - you may call this on either rows or columns
      # @param meth - min/max
      # @param aggregate - functions from cell.rb to be used to aggregate e.g. avg_spanned_min_width
      #
      def aggregate_cell_values(row_or_column, meth, aggregate)
        values = {}

        #calculate values for all cells that do not span accross multiple cells
        #this ensures that we don't have a problem if the first line includes
        #a cell that spans across multiple cells
        @cells.each do |cell|
          #don't take spanned cells
          if cell.colspan == 1 and cell.class != Prawn::Table::Cell::SpanDummy
            index = cell.send(row_or_column)
            values[index] = [values[index], cell.send(meth)].compact.send(aggregate)
          end
        end

        # if there are only colspanned or rowspanned cells in a table
        spanned_width_needs_fixing = true

        @cells.each do |cell|
          index = cell.send(row_or_column)
          if cell.colspan > 1
            #special treatment if some but not all spanned indices in the values array have been calculated
            #only applies to rows
            values = fill_values_if_needed(values, cell, index, meth) if row_or_column == :column
            #calculate current (old) return value before we do anything
            old_sum = 0
            cell.colspan.times { |i|
              old_sum += values[index+i] unless values[index+i].nil?
            }

            #calculate future return value
            new_sum = cell.send(meth) * cell.colspan

            #due to float rounding errors we need to ignore a small difference in the new
            #and the old sum the same had to be done in
            #the column_width_calculator#natural_width
            spanned_width_needs_fixing = ((new_sum - old_sum) > Prawn::FLOAT_PRECISION)

            if spanned_width_needs_fixing
              #not entirely sure why we need this line, but with it the tests pass
              values[index] = [values[index], cell.send(meth)].compact.send(aggregate)
              #overwrite the old values with the new ones, but only if all entries existed
              entries_exist = true
              cell.colspan.times { |i| entries_exist = false if values[index+i].nil? }
              cell.colspan.times { |i|
                values[index+i] = cell.send(meth) if entries_exist
              }
            end
          else
            if spanned_width_needs_fixing && cell.class == Prawn::Table::Cell::SpanDummy
              values[index] = [values[index], cell.send(meth)].compact.send(aggregate)
            end
          end
        end

        return values.values.inject(0, &:+)
      end
    end

  end
end
