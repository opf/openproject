class HourlyRateObserver < ActiveRecord::Observer
  def after_create(rate)
    next_rate = self.next_rate(rate)
    
    if next_rate.nil?
      time_entries = TimeEntry.find(:all, :conditions => ["spent_on >= ? AND user_id = ? and project_id = ?", rate.valid_from, rate.user, rate.project])
    else
      time_entries = TimeEntry.find(:all, :conditions => {:spent_on => rate.valid_from..(next_rate.valid_from - 1), :user_id => rate.user, :project_id => rate.project})
    end
    
    update_time_entries(time_entries, rate)
  end
  
  def after_update(rate)
    return unless rate.valid_from.changed?
    
    conditions = get_conditions(:valid_from, rate.valid_from_was, rate.valid_from)
    conditions = conditions.merge({:user_id => rate.user, :project_id => rate.project})
    
    if HourlyRate.count(:conditions => conditions) > 0
      # We have passed the boundary of another rate
      
      # First update all entries that were previously assigned to the current rate
      old_next_rate = self.next_rate(rate, rate.valid_from_was)
      if old_next_rate.nil?
        time_entries = TimeEntry.find(:all, :conditions => ["spent_on >= ? AND user_id = ? and project_id = ?", rate.valid_from_was, rate.user, rate.project])
      else
        time_entries = TimeEntry.find(:all, :conditions => {:spent_on => rate.valid_from_was..(old_next_rate.valid_from - 1), :user_id => rate.user, :project_id => rate.project})
      end
      
      update_time_entries(time_entries, previous_rate(rate, rate.valid_from_was))
      
      # Now update all entries that are newly assigned to the current rate
      after_create(rate)
    else
      # We have only moved the rate without passing other rates
      conditions = get_conditions(:spent_on, rate.valid_from_was, rate.valid_from)
      conditions = conditions.merge({:user_id => rate.user, :project_id => rate.project})
      
      time_entries = TimeEntry.find(:all, :conditions => conditions)
      update_time_entries(time_entries, (rate.valid_from_was < rate.valid_from) ? previous_rate(rate) : rate)
    end
  end
  
private
  def next_rate(rate, date = rate.valid_from)
    HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id = ? and valid_from > ?", rate.user, rate.project, date], :order => "valid_from ASC")
  end
  
  def previous_rate(rate, date = rate.valid_from)
    rate.user.rate_at(rate.project, date - 1)
  end
  
  def get_conditions(param, date1, date2)
    if rate.valid_from_was < rate.valid_from
      {param => date1..date2}
    else
      {param => date2..date1}
    end
  end
  
  def update_time_entries!(time_entries, rate)
    time_entries.each do |time_entry|
      time_entry.update_costs!(rate)
    end
  end
  
end