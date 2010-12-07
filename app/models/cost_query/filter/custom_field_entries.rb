class CostQuery::Filter
  class CustomFieldEntries < Base
    extend CostQuery::CustomFieldMixin

    on_prepare do
      applies_for :label_issue_attributes
      # redmine internals just suck
      case custom_field.field_format
      when 'string', 'text' then use :string_operators
      when 'list'           then use :null_operators
      when 'date'           then use :time_operators
      when 'int', 'float'   then use :integer_operators
      when 'bool'
        @possible_values = [['true', 't'], ['false', 'f']]
        use :null_operators
      else
        fail "cannot handle #{custom_field.field_format.inspect}"
      end
    end

    def self.available_values(*)
      @possible_values || custom_field.possible_values
    end
  end
end
