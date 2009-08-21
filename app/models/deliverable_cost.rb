class DeliverableCost < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :rate, :class_name => "CostRate", :foreign_key => 'rate_id'
  
  def costs
    rate.rate * units
  end
end