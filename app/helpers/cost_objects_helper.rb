require 'csv'

module CostObjectsHelper
  include ApplicationHelper

  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    return User.current.allowed_to?(:edit_cost_objects, @project)
  end

  def cost_objects_to_csv(cost_objects)
    CSV.generate(:col_sep => l(:general_csv_separator)) do |csv|
      # csv header fields
      headers = [ "#",
                  CostObject.human_attribute_name(:status),
                  Project.model_name.human,
                  CostObject.human_attribute_name(:subject),
                  CostObject.human_attribute_name(:author),
                  CostObject.human_attribute_name(:fixed_date),
                  VariableCostObject.human_attribute_name(:material_budget),
                  VariableCostObject.human_attribute_name(:labor_budget),
                  CostObject.human_attribute_name(:spent),
                  CostObject.human_attribute_name(:created_on),
                  CostObject.human_attribute_name(:updated_on),
                  CostObject.human_attribute_name(:description)
                  ]
      csv << headers.collect {|c| begin; c.to_s.encode('UTF-8'); rescue; c.to_s; end }
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
        csv << fields.collect {|c| begin; c.to_s.encode('UTF-8'); rescue; c.to_s; end }
      end
    end
  end
end
