class CostType < ActiveRecord::Base
  has_many :material_budget_items
  has_many :cost_entries, :dependent => :destroy
  has_many :rates, :class_name => "CostRate", :foreign_key => "cost_type_id", :dependent => :destroy
  
  validates_presence_of :name, :unit, :unit_plural
  validates_uniqueness_of :name
  
  after_update :save_rates
  
  # finds the default CostType
  def self.default
    result = CostType.find(:first, :conditions => { :default => true})
    result ||= CostType.find(:first)
    result
  rescue ActiveRecord::RecordNotFound
    nil
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
  
  def new_rate_attributes=(rate_attributes)
    rate_attributes.each do |index, attributes|
      attributes[:rate] = Rate.clean_currency(attributes[:rate])
      rates.build(attributes)
    end
  end
  
  def existing_rate_attributes=(rate_attributes)
    rates.reject(&:new_record?).each do |rate|
      attributes = rate_attributes[rate.id.to_s]
      
      has_rate = false
      if attributes && attributes[:rate].present?
        attributes[:rate] = Rate.clean_currency(attributes[:rate])
        has_rate = true
      end
      
      if has_rate
        rate.attributes = attributes
      else
        rates.delete(rate)
      end
    end
  end
  
  def save_rates
    rates.each do |rate|
      rate.save(false)
    end
  end
  
  
end