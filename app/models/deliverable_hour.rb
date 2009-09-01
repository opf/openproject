class DeliverableHour < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :user

  validates_length_of :comments, :maximum => 255, :allow_nil => true
  
  def costs
    self.budget || self.calculated_costs
  end
  
  def calculated_costs
    hours && user ? user.rate_at(deliverable.fixed_date, deliverable.project_id).rate * hours : 0.0
  end
  
  def can_view_costs?(usr, project)
    usr.allowed_to?(:view_all_rates, project) || (user && usr == user && user.allowed_to?(:view_own_rate, project))
  end
end