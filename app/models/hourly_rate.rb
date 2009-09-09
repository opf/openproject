class HourlyRate < Rate
  belongs_to :user
  belongs_to :project
  
  def self.default(params = {})
    DefaultHourlyRate.new(params)
  end
  
  def self.history_for_user(user, for_display = true)
    rates = Hash.new
    user.projects.each do |project|
      next unless (!for_display ||
                   User.current.allowed_to?(:view_all_rates, project) ||
                   user == User.current && User.current.allowed_to?(:view_own_rate, project)
                  )

      rates[project] = HourlyRate.find(:all,
          :conditions => { :user_id => user, :project_id => project },
          :order => "#{HourlyRate.table_name}.valid_from desc")
    end
    rates
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