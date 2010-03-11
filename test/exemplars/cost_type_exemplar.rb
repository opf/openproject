CostType.class_eval do
  generator_for :name, :method => :next_name
  generator_for :unit, "EURO"
  generator_for :unit_plural, "EUROS"
  generator_for :default, 0
  
  def self.next_name
    @next_generated_name ||= "CostType 0"
    @next_generated_name.succ!
    @next_generated_name
  end
end