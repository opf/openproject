class CostBasedDeliverable < Deliverable
  has_many :deliverable_costs, :include => :rate, :foreign_key => 'deliverable_id'
  has_many :deliverable_hours, :include => :rate, :foreign_key => 'deliverable_id'

  # Label of the current type for display in GUI.
  def type_label
    return l(:label_cost_based_deliverable)
  end
end