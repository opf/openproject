class DeliverableCost < ActiveRecord::Base
  belongs_to :deliverable
  belongs_to :cost_type

  # def self.new(params={})
  #   unless params[:rate_id] || params[:rate]
  #     if new_cost_type = params.delete(:cost_type)
  #       params[:rate] = new_cost_type.current_rate
  #     elsif new_cost_type_id = params.delete(:cost_type_id)
  #       params[:rate] = CostType.find(new_cost_type_id).current_rate
  #     else
  #       params[:rate] = CostType.default.current_rate
  #     end
  #   end
  #   super(params)
  # end
  
  def costs
    units && cost_type ? cost_type.rate_at(deliverable.fixed_date).rate * units : 0.0
  end
end