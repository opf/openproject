module Report::Validation
  module Dates
    def validate_dates(*values)
      values = values.flatten
      return true if values.empty?
      values.flatten.all? do |val|
        begin
          !!val.to_dateish
        rescue ArgumentError
          errors << "\'#{val}\' " + l(:validation_failure_date)
          validate_dates(values - [val])
          false
        end
      end
    end
  end
end