class HourlyRateObserver < ActiveRecord::Observer
  class Methods
    def initialize(changed_rate)
      self.rate = changed_rate
    end
    
    def entries_after(date)
      [
        "spent_on >= ? AND user_id = ? and project_id = ?",
        date, self.rate.user, self.rate.project
      ]
    end

    def entries_between(date1, date2 = nil)
      # if the second date is not given, return all entries
      # with a spent_on after the given date
      return entries_after(date1 || date2) if date1.nil || date2.nil?
      
      # order the dates
      if date2 < date1
        date_tmp = date2
        date2 = date1
        date1 = date_tmp
      end
      
      # return conditions for all time entries between date1 and date2 - 1 day
      { :spent_on => date1..(date2 - 1),
        :user_id => self.rate.user,
        :project_id => self.rate.project
      }
    end
    
    def find_entries(date1, date2 = nil)
      TimeEntry.find(:all, :conditions => entries_between(date1, date2))
    end
        
    def update_entries(entries, rate = self.rate)
      # This methods updates the given array of time_entries with the given rate
      entries = [entries] unless entries.is_a?(Array)
      entries.each do |entry|
        entry.update_costs!(rate)
      end
    end
  end
  
  def after_create(rate)
    o = Methods.new(rate)

    next_rate = rate.next_rate
    time_entries = o.fine_time_entries(rate.valid_from, (next_rate.valid_from if next_rate))
    
    o.update_entries(time_entries)
  end
  
  def after_update(rate)
    o = Methods.new(rate)
    
    unless rate.valid_from.changed?
      # We have not moved a rate, maybe just changed the rate value
      
      return unless rate.rate_changed?
      # Only the rate value was changed so just update the currently assigned entries
      return after_create(rate)
    end
    
    # We have definitely moved the rate
    if HourlyRate.count(entries_between(rate.valid_from_was, rate.valid_from)) > 0
      # We have passed the boundary of another rate
      # We do essantially the same as deleting the old rate and adding a new one

      # So first assign all entries from the old a new rate
      after_destroy(rate)
      
      # Now update the newly assigned entries
      after_create(rate)
    else
      # We have only moved the rate without passing other rates
      # So we have to either assign some entries to our previous rate (if moved forwards)
      # or assign some entries to self (if moved backwards)
      
      time_entries = o.find_time_entries(rate.valid_from_was, rate.valid_from)
      o.update_time_entries(time_entries, (rate.valid_from_was < rate.valid_from) ? rate.previous : rate)
    end
  end
  
  def after_destroy(rate)
    o = Methods.new(rate)

    # Update all entries that were previously assigned to the current rate
    # That are all entries between valid_from and next_rate.valid_from (regading the old state)
    # They get the previous rate assigned (regarding the old state)
    old_next_rate = rate.next(rate.valid_from_was)
    time_entries = o.find_entries(
      rate.valid_from_was,
      (old_next_rate.valid_from if old_next_rate)
    )
    o.update_time_entries(time_entries, rate.previous(rate.valid_from_was))
  end
end