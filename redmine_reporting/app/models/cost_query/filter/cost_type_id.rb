class CostQuery::Filter::CostTypeId < CostQuery::Filter::Base
  label :field_cost_type

  def initialize(child = nil, options = {})
    @display = options.delete(:display)
    super
  end

  def display?
    return super if @display.nil?
    @display
  end

  def self.available_values(*)
    ([[l(:caption_labor), -1]] + CostType.find(:all, :order => 'name').map { |t| [t.name, t.id] })
  end
end
