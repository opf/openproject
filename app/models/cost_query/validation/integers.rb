module CostQuery::Validation
  module Integers
    def validate_integers(values = [])
      values_passed = true
      values.all? do |val|
        if val.to_i.to_s != val.to_s
          values_passed = false
          errors << "\'#{val}\' is not a valid date!"
        end
      end
      values_passed
    end
  end
end