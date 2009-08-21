class HourlyRate < Rate
  belongs_to :user
  belongs_to :project
  
  def self.current_rate(user_id, project_id)
    current_rate = HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id = ? and valid_from <= ?", user_id, project_id, Date.today], :order => "valid_from DESC")
    current_rate ||= DefaultHourlyRate.new(:user_id => user_id, :project_id => project_id)
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