class CostRate < Rate
  belongs_to :cost_type
  
  validates_uniqueness_of :valid_from, :scope => :cost_type_id
  validates_presence_of :cost_type_id
  
  def validate
    # Only allow change of project and user on first creation
    return if self.new_record?
    
    errors.add :cost_type_id, :activerecord_error_invalid if cost_type_id_changed?
  end
  
end