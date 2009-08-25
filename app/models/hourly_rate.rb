class HourlyRate < Rate
  belongs_to :user
  belongs_to :project
  
  def self.default(params = {})
    DefaultHourlyRate.new(params)
  end
end

class DefaultHourlyRate < HourlyRate
  def rate
    0.0
  end
  
  def valid_from
    Date.new
  end
end