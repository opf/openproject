module Report::Validation
  module Dates
    def validate_dates(*values)
      values = values.flatten
      return true if values.empty?
      values.flatten.all? do |val|
        begin
          !!val.to_dateish
        rescue ArgumentError
          errors[:date] << val
          validate_dates(values - [val])
          false
        end
      end
    end
  end
end