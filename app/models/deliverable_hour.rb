class DeliverableHour < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :rate, :class_name => "HourlyRate", :foreign_key => 'rate_id'
  
  def costs
    costs = rate.rate * hours
  end
  
  def can_view_costs?(usr, project)
    user = rate.user if rate

    a = usr.allowed_to?(:view_all_rates, project) || (user && usr == user && user.allowed_to?(:view_own_rate, project))
  end
end