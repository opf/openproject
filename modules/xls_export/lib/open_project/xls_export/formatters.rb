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
        name = self.name.demodulize.underscore
        name[0..(name.index("_") - 1)].to_sym
      end

      ##
      # Takes a WorkPackage and a QueryColumn and returns the value to be exported.
      def format(work_package, column)
        value = column.xls_value work_package

        if value.is_a? Array
          value.join(", ")
        else
          value
        end
      end

      ##
      # Takes a QueryColumn and returns format options for it.
      def format_options(column)
        {}
      end
    end

    class TimeFormatter < DefaultFormatter
      def format_options(column)
        { :number_format => '0.0 "h"' }
      end
    end

    class CostFormatter < DefaultFormatter
      def format_options(column)
        { :number_format => number_format_string }
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
