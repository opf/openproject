class CostType < ActiveRecord::Base
  unloadable
  
  has_many :deliverables, :through => :deliverable_costs
  has_many :cost_entries, :dependent => :destroy
  
  validates_presence_of :name, :unit, :unit_plural, :unit_price, :valid_from
  validates_uniqueness_of :name
  validates_numericality_of :unit_price, :allow_nil => false, :message => :activerecord_error_invalid
  
  # finds the default CostType
  def self.default
    CostType.find(:first, :conditions => { :default => true})
  rescue ActiveRecord::RecordNotFound
    return nil
  end
  
  def is_default
    self.default
  end
  
  def <=>(cost_type)
    name.downcase <=> cost_type.name.downcase
  end
end