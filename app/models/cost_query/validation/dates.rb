module CostQuery::Validation
  module Dates
    def validate_dates(values = [])
      values.all? do |val|
        begin
          !!val.to_dateish
        rescue ArgumentError
          validate_dates(values - [val])
          errors << "\'#{val}\' is not a valid date!"
          false
        end
      end
    end
  end
end