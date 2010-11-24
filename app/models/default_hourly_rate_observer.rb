class DefaultHourlyRateObserver < ActiveRecord::Observer
  class Methods
    def initialize(changed_rate)
      @rate = changed_rate
    end
    
    def order_dates(date1, date2)
      # order the dates
      return date1 || date2 if date1.nil? || date2.nil?

      if date2 < date1
        date_tmp = date2
        date2 = date1
        date1 = date_tmp
      end
      [date1, date2]
    end

    def orphaned_child_entries(date1, date2 = nil)
      # This method returns all entries in all projects without an explicit rate
      # between date1 and date2
      # i.e. the ones with an assigned default rate or without a rate
      
      (date1, date2) = order_dates(date1, date2)
      
      # This gets an array of all the ids of the DefaultHourlyRates
      default_rates = DefaultHourlyRate.find(:all, :select => :id).inject([]){|r,d|r<<d.id}
      
      if date1.nil? || date2.nil?
        # we have only one date, query >=
        conditions = [
          "user_id = ? AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on >= ?",
          @rate.user_id, default_rates, date1 || date2
        ]
      else
        # we have two dates, query between
        conditions = [
          "user_id = ? AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on BETWEEN ? AND ?",
          @rate.user_id, default_rates, date1, date2 - 1
        ]
      end
      
      TimeEntry.find(:all, :conditions => conditions, :include => :rate)
    end
    
    def update_entries(entries, rate = @rate)
      # This methods updates the given array of time or cost entries with the given rate
      entries = [entries] unless entries.is_a?(Array)
      ActiveRecord::Base.cache do
        entries.each do |entry|
          entry.update_costs!(rate)
        end
      end
    end
  end
  
  def after_create(rate)
    o = Methods.new(rate)

    next_rate = rate.next
    # and entries from all projects that need updating
    entries = o.orphaned_child_entries(rate.valid_from, (next_rate.valid_from if next_rate))
    
    o.update_entries(entries)
  end
  
  def after_update(rate)
    # FIXME: This might be extremly slow. Consider using an implementation like in HourlyRateObserver
    unless rate.valid_from_changed?
      # We have not moved a rate, maybe just changed the rate value
      
      return unless rate.rate_changed?
      # Only the rate value was changed so just update the currently assigned entries
      return after_create(rate)
    end
    
    after_destroy(rate)
    after_create(rate)
  end
  
  def after_destroy(rate)
    o = Methods.new(rate)

    o.update_entries(TimeEntry.find(:all, :conditions => {:rate_id => rate.id}))
  end
end