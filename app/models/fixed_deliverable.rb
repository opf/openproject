class FixedDeliverable < Deliverable
  unloadable
  
  # Label of the current type for display in GUI.
  def type_label
    return l(:label_fixed_deliverable)
  end
end