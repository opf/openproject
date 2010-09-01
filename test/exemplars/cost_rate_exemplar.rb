CostRate.class_eval do
  generator_for :cost_type, :method => :next_cost_type

  def self.next_cost_type
    CostType.last || CostType.generate!
  end
end
