require 'report'

class CostQuery < Report
  def_delegators :result, :real_costs

end

