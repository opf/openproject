module CostQuery::Validation
  module Integers
    def validate_integers(*values)
      values = values.flatten
      return true if values.empty?
      values.flatten.all? do |val|
        if val.to_i.to_s != val.to_s
          errors[:int] << val
          validate_integers(values - [val])
          false
        else
          true
        end
      end
    end
  end
end