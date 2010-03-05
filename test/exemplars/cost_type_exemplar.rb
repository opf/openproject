class CostType < ActiveRecord::Base
  generator_for :name, :method => :next_name
  generator_for :unit, "EURO"
  generator_for :unit_plural, "EUROS"
  
  def self.next_name
    @next_generated_name ||= "CostType 0"
    @next_generated_name.succ!
    @next_generated_name
  end
end