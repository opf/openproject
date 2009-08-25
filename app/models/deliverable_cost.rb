class DeliverableCost < ActiveRecord::Base
  belongs_to :deliverable
  belongs_to :rate, :class_name => "CostRate", :foreign_key => 'rate_id'
  
  def self.new(params={})
    unless params[:rate_id] || params[:rate]
      if new_cost_type = params.delete(:cost_type)
        params[:rate] = new_cost_type.current_rate
      elsif new_cost_type_id = params.delete(:cost_type_id)
        params[:rate] = CostType.find(new_cost_type_id).current_rate
      else
        params[:rate] = CostType.default.current_rate
      end
    end
    super(params)
  end
  
  def cost_type
    rate.cost_type
  end
  
  def cost_type=(new_cost_type)
    self.rate = new_cost_type.current_rate
  end
  
  def cost_type_id
    rate.cost_type_id
  end
  
  def cost_type_id=(new_cost_type_id)
    self.rate = CostType.find(new_cost_type_id).current_rate
  end
  
  def costs
    rate && units ? rate.rate * units : 0.0
  end
end