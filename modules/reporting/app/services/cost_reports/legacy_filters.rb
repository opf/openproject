# frozen_string_literal: true

module CostReports
  # Filters used to be passed as fields[]/operators[]/values[] and kept in the
  # session. Links created before that changed are still out there, so both are
  # translated into the compact syntax the url uses now.
  class LegacyFilters
    CUSTOM_FIELD = /\ACustomField(\d+)\z/i

    # The session keys these by symbol, request parameters by string.
    def initialize(operators:, values:, rows: [], columns: [])
      @operators = normalize(operators)
      @values = normalize(values)
      @rows = Array(rows)
      @columns = Array(columns)
    end

    def to_params
      { filters: filters_param, rows: axis(@rows), columns: axis(@columns) }.compact_blank
    end

    def any?
      @operators.any? || @rows.any? || @columns.any?
    end

    private

    def normalize(hash)
      case hash
      when ActionController::Parameters then hash.permit!.to_h.stringify_keys
      when Hash then hash.stringify_keys
      else {}
      end
    end

    def filters_param
      @operators.map { |name, operator| filter_string(name, operator) }.join(" & ")
    end

    def filter_string(name, operator)
      "#{attribute_for(name)} #{operator} #{quoted(Array(@values[name]))}".rstrip
    end

    # The engine addressed its filters by class name, e.g. WorkPackageId or
    # CustomField7, where the modern ones use the attribute.
    def attribute_for(name)
      match = CUSTOM_FIELD.match(name.to_s)

      match ? "cf_#{match[1]}" : name.to_s.underscore
    end

    def quoted(values)
      quoted = values.compact.map { |value| %("#{value.to_s.gsub('"', '\"')}") }

      return quoted.join if quoted.size <= 1

      "[#{quoted.join(',')}]"
    end

    def axis(dimensions)
      Array(dimensions).map { |dimension| attribute_for(dimension) }.join(",")
    end
  end
end
