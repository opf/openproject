module CostQuery::Validation
  module CostQuery::Validation::DateValidation
    include CostQuery::Validation

    def validate(*values)
      errors.clear
      values.all? do |vals|
        vals = vals.is_a?(Array) ? vals : [vals]
        vals.all? do |val|
          begin
            !!val.to_dateish
          rescue ArgumentError
            validate(vals - [val])
            errors << "\'#{val}\' is not a valid date!"
            false
          end
        end
      end
    end
  end

  def validate(*values)
    true
  end

  def errors
    @errors ||= []
    @errors
  end

end