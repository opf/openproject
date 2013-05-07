class MaterialBudgetItem < ActiveRecord::Base
  unloadable

  belongs_to :cost_object
  belongs_to :cost_type

  validates_length_of :comments, :maximum => 255, :allow_nil => true
  validates_presence_of :cost_type

  include ActiveModel::ForbiddenAttributesProtection

  def self.visible_condition(user, project)
    Project.allowed_to_condition(user,
                                 :view_cost_rates,
                                 :project => project)
  end

  scope :visible_costs, lambda{|*args|
    { :include => [{:cost_object => :project}],
      :conditions => MaterialBudgetItem.visible_condition((args.first || User.current), args[1])
    }
  }

  def costs
    self.budget || self.calculated_costs
  end

  def calculated_costs(fixed_date = cost_object.fixed_date)
    if units && cost_type && rate = cost_type.rate_at(fixed_date)
      rate.rate * units
    else
      0.0
    end
  end

  def costs_visible_by?(usr)
    usr.allowed_to?(:view_cost_rates, cost_object.project)
  end
end
