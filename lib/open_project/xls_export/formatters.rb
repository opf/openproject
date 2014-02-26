module OpenProject::XlsExport
  module Formatters
    def self.all
      self.constants.map do |const|
        Kernel.const_get("OpenProject::XlsExport::Formatters::#{const}")
      end.select do |const|
        const.is_a?(Class) && const != DefaultFormatter
      end + [DefaultFormatter]
    end

    def self.keys
      all.map(&:key)
    end

    ##
    # Returns a Hash mapping columns to formatters to be used.
    def self.for_columns(columns)
      formatters = self.all
      entries = columns.map do |column|
        formatter = formatters.find { |formatter| formatter.apply? column }
        [column, (formatter || DefaultFormatter).new]
      end
      Hash[entries]
    end

    class DefaultFormatter
      ##
      # Takes a QueryColumn and returns true if this formatter should be used to handle it.
      def self.apply?(column)
        column.xls_formatter == self.key
      end

      def self.key
        name = self.name.underscore
        name[0..(name.index("_") - 1)].to_sym
      end

      ##
      # Takes a WorkPackage and a QueryColumn and returns the value to be exported.
      def format(work_package, column)
        column.xls_value work_package
      end

      ##
      # Takes a QueryColumn and returns format options for it.
      def format_options(column)
        {}
      end
    end

    class TimeFormatter < DefaultFormatter
      def self.apply?(column)
        ##
        # Fallback for code not defining any xls formatter.
        # If there are columns with 'hours' in their caption that should
        # not use the time formatter, they can simply define #xls_formatter
        # to use something else, e.g. :default.
        if column.xls_formatter.nil?
          h = column.caption
          h =~ /.*hours.*/i || h == "spent_time"
        else
          super.apply? column
        end
      end

      def format_options(column)
        {:number_format => '0.0 "h"'}
      end
    end

    class CostFormatter < DefaultFormatter
      def self.apply?(column)
        ##
        # Fallback for code not defining any xls formatter.
        # If there are columns with 'cost' in their caption that should
        # not use the cost formatter, they can simply define #xls_formatter
        # to use something else, e.g. :default.
        if column.xls_formatter.nil?
          column.caption.to_s =~ /.*cost.*/i
        else
          super.apply?(column)
        end
      end

      def format_options(column)
        {:number_format => number_format_string}
      end

      def number_format_string
        # [$CUR] makes sure we have an actually working currency format with arbitrary currencies
        curr = "[$CUR]".gsub "CUR", ERB::Util.h(Setting.plugin_openproject_costs['costs_currency'])
        format = ERB::Util.h Setting.plugin_openproject_costs['costs_currency_format']
        number = '#,##0.00'

        format.gsub("%n", number).gsub("%u", curr)
      end
    end
  end
end
