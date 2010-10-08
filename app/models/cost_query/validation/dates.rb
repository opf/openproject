module CostQuery::Validation
  module Dates
    def validate_dates(values = [])
      values.all? do |val|
        begin
          !!val.to_dateish
        rescue ArgumentError
          validate_dates(values - [val])
          errors << "\'#{val}\' " + l(:validation_failure_date)
          false
        end
      end
    end
  end
end