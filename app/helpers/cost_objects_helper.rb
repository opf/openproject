require 'csv'

module CostObjectsHelper
  include ApplicationHelper
    
  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    return User.current.allowed_to?(:edit_cost_objects, @project)
  end
  
  def cost_objects_to_csv(cost_objects, project)
    ic = Iconv.new(l(:general_csv_encoding), 'UTF-8')    
    decimal_separator = l(:general_csv_decimal_separator)
    export = StringIO.new
    CSV::Writer.generate(export, l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  l(:field_status), 
                  l(:field_project),
                  l(:field_subject),
                  l(:field_author),
                  l(:field_fixed_date),
                  l(:field_material_budget),
                  l(:field_labor_budget),
                  l(:field_spent),
                  l(:field_created_on),
                  l(:field_updated_on),
                  l(:field_description)
                  ]
      csv << headers.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      # csv lines
      cost_objects.each do |cost_object|
        fields = [cost_object.id,
                  l(cost_object.status), 
                  cost_object.project.name,
                  cost_object.subject,
                  cost_object.author.name,
                  format_date(cost_object.fixed_date),
                  cost_object.kind == "VariableCostObject" ? number_to_currency(cost_object.material_budget) : "",
                  cost_object.kind == "VariableCostObject" ? number_to_currency(cost_object.labor_budget) : "",
                  cost_object.kind == "VariableCostObject" ? number_to_currency(cost_object.spent) : "",
                  format_time(cost_object.created_on),  
                  format_time(cost_object.updated_on),
                  cost_object.description
                  ]
        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    export
  end
end