class CostRate < Rate
  belongs_to :cost_type
  
  validates_uniqueness_of :valid_from, :scope => :cost_type_id

end