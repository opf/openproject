class CostQuery::Filter::CostTypeId < Report::Filter::Base
  extra_options :display
  selectable false

  def self.label
    WorkPackage.human_attribute_name(:cost_type)
  end

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
