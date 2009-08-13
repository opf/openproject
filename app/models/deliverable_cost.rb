class DeliverableCost < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :cost_type
  
  def costs
    cost_type.unit_price * units
  end
end