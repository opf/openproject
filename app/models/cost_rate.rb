class CostRate < Rate
  belongs_to :cost_type
  
  validates_uniqueness_of :valid_from, :scope => :cost_type_id
  
  def validate
    # Only allow change of project and user on first creation
    return if self.new_record?
    
    errors.add :cost_type_id, :activerecord_error_invalid if cost_type_id_changed?
  end
  
  def previous(reference_date = self.valid_from)
    # This might return a default rate
    self.cost_type.rate_at(reference_date - 1)
  end
  
  def next(reference_date = self.valid_from)
    CostRate.find(
      :first,
      :conditions => [ "cost_type_id = ? and valid_from > ?",
        self.cost_type_id, reference_date],
      :order => "valid_from ASC"
    )
  end
  
  
end