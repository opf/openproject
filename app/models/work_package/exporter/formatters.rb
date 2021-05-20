module WorkPackage::Exporter
  module Formatters
    def self.all
      @formatters ||= begin
        %i[default costs estimated_hours].map do |key|
          Kernel.const_get("WorkPackage::Exporter::Formatters::#{key.to_s.camelize}")
        end
      end
    end

    def self.keys
      all.map(&:key)
    end

    def self.register(clz)
      @formatters << clz
    end

    ##
    # Returns a matching formatter for the given query column
    def self.for_column(column)
      formatter = all.find { |formatter| formatter.apply? column } || Default
      formatter.new
    end
  end
end
