class CostQuery::Filter::CostTypeId < CostQuery::Filter::Base
  label :field_cost_type
  extra_options :display
  selectable false

  def initialize(child = nil, options = {})
    super
    @display = options[:display]
  end

  ##
  # @Override
  # Displayability is decided on the instance
  def display?
    return super if @display.nil?
    @display
  end

  def self.available_values(*)
    ([[::I18n.t(:caption_labor), -1]] + CostType.find(:all, :order => 'name').map { |t| [t.name, t.id] })
  end
end
