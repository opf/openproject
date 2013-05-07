class LaborBudgetItem < ActiveRecord::Base
  unloadable

  belongs_to :cost_object
  belongs_to :user
  include ::OpenProject::Costs::DeletedUserFallback

  validates_length_of :comments, :maximum => 255, :allow_nil => true
  validates_presence_of :user
  validates_presence_of :cost_object
  validates_numericality_of :hours, :allow_nil => false

  include ActiveModel::ForbiddenAttributesProtection
  # user_id correctness is ensured in VariableCostObject#*_labor_budget_item_attributes=

  def self.visible_condition(user, project)
    %Q{ (#{Project.allowed_to_condition(user,
                                        :view_hourly_rates,
                                        :project => project)} OR
         (#{Project.allowed_to_condition(user,
                                         :view_own_hourly_rate,
                                         :project => project)} AND #{LaborBudgetItem.table_name}.user_id = #{user.id})) }
  end

  scope :visible_costs, lambda{|*args|
    { :include => [{:cost_object => :project}, :user],
      :conditions => LaborBudgetItem.visible_condition((args.first || User.current), args[1])
    }
  }

  def costs
    self.budget || self.calculated_costs
  end

  def calculated_costs(fixed_date = cost_object.fixed_date, project_id = cost_object.project_id)
    if user_id && hours && rate = HourlyRate.at_date_for_user_in_project(fixed_date, user_id, project_id)
      rate.rate * hours
    else
      0.0
    end
  end

  def costs_visible_by?(usr)
    usr.allowed_to?(:view_hourly_rates, cost_object.project) ||
      (usr.id == user_id && usr.allowed_to?(:view_own_hourly_rate, cost_object.project))
  end
end
