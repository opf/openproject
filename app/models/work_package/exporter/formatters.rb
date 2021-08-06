module WorkPackage::Exporter
  module Formatters
    def self.default_formatter_strings
      @default_formatter_strings ||= %i[default costs estimated_hours].map do |key|
        "WorkPackage::Exporter::Formatters::#{key.to_s.camelize}"
      end
    end

    def self.all_formatter_strings
      @all_formatter_strings ||= default_formatter_strings
    end

    def self.all
      all_formatter_strings.map do |formatter_string|
        Kernel.const_get(formatter_string)
      end
    end

    def self.keys
      all.map(&:key)
    end

    def self.register(class_string)
      @all_formatter_strings = all_formatter_strings + [class_string]
    end

    ##
    # Returns a matching formatter for the given query column
    def self.for_column(column)
      formatter = all.find { |formatter| formatter.apply? column } || Default
      formatter.new
    end
  end
end
