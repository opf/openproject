class CostType < ActiveRecord::Base
  unloadable
  
  has_many :deliverable_costs
  has_many :cost_entries, :dependent => :destroy
  
  belongs_to :rate, :class_name => 'CostRate', :foreign_key => 'rate_id'
  
  validates_presence_of :name, :unit, :unit_plural, :unit_price, :valid_from
  validates_uniqueness_of :name
  
  # finds the default CostType
  def self.default
    CostType.find(:first, :conditions => { :default => true})
  rescue ActiveRecord::RecordNotFound
    CostType.find(:first)
  end
  
  def is_default
    self.default
  end
  
  def <=>(cost_type)
    name.downcase <=> cost_type.name.downcase
  end
  
  def current_rate
    CostRate.find(:first, :conditions => { :cost_type_id => id}, :order => "valid_from DESC")
  rescue ActiveRecord::RecordNotFound
    return nil
  end
end