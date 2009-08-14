class DeliverableCost < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :cost_type
  
  def costs
    # FIXME: This calculation does not use the valid_from field
    r = cost_type.current_rate
    r ? r.rate * units : 0.0
  end
end