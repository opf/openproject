class CostType < ActiveRecord::Base
  unloadable
  
  has_many :deliverable_costs
  has_many :cost_entries, :dependent => :destroy
  has_many :rates, :class_name => "CostRate", :foreign_key => "cost_type_id", :dependent => :destroy
  
  validates_presence_of :name, :unit, :unit_plural, :unit_price, :valid_from
  validates_uniqueness_of :name
  
  # finds the default CostType
  def self.default
    CostType.find(:first, :conditions => { :default => true})
  rescue ActiveRecord::RecordNotFound
    CostType.find(:first)
  end
  
  def is_default?
    self.default
  end
  
  def <=>(cost_type)
    name.downcase <=> cost_type.name.downcase
  end
  
  def current_rate
    rate_at(Date.today)
  end
  
  def rate_at(date)
    CostRate.find(:first, :conditions => [ "cost_type_id = ? and valid_from <= ?", id, date], :order => "valid_from DESC")
  rescue ActiveRecord::RecordNotFound
    return nil
  end
  
  def to_s
    name
  end
end