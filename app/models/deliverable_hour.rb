class DeliverableHour < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :rate
  
  def costs
    rate.hourly_price * hours
  end
end