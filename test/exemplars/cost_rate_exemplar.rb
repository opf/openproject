Rate.class_eval do
  generator_for :valid_from, :method => :next_valid_from
  generator_for :rate, 10
  generator_for :cost_type, :method => :next_cost_type
   
  def self.next_cost_type
    CostType.last || CostType.generate!
  end
  
  def self.next_valid_from
    1.year.ago + Rate.count
  end
end