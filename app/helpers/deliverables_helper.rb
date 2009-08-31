require 'csv'

module DeliverablesHelper
  include ApplicationHelper
    
  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    return User.current.allowed_to?(:edit_deliverables, @project)
  end
  
  def fields_for_deliverable_cost(deliverable_cost, &block)
    prefix = deliverable_cost.new_record? ? "new" : "existing"
    fields_for("deliverable[#{prefix}_deliverable_cost_attributes][]", deliverable_cost, &block)
  end

  def deliverables_to_csv(deliverables, project)
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
      deliverables.each do |deliverable|
        fields = [deliverable.id,
                  l(deliverable.status), 
                  deliverable.project.name,
                  deliverable.subject,
                  deliverable.author.name,
                  format_date(deliverable.fixed_date),
                  deliverable.kind == "CostBasedDeliverable" ? number_to_currency(deliverable.material_budget) : "",
                  deliverable.kind == "CostBasedDeliverable" ? number_to_currency(deliverable.labor_budget) : "",
                  deliverable.kind == "CostBasedDeliverable" ? number_to_currency(deliverable.spent) : "",
                  format_time(deliverable.created_on),  
                  format_time(deliverable.updated_on),
                  deliverable.description
                  ]
        csv << fields.collect {|c| begin; ic.iconv(c.to_s); rescue; c.to_s; end }
      end
    end
    export.rewind
    export
  end




end