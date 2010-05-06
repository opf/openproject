class RateObserver < ActiveRecord::Observer
  observe :hourly_rate, :cost_rate
  
  class Methods
    def initialize(changed_rate)
      @rate = changed_rate
    end
    
    # order the dates
    def order_dates(*dates)
      dates.compact!
      dates.size == 1 ? dates.first : dates.sort
    end
    
    def conditions_after(date, date_column = :spent_on)
      if @rate.is_a?(HourlyRate)
        [
          "#{date_column} >= ? AND user_id = ? and project_id = ?",
          date, @rate.user_id, @rate.project_id
        ]
      else
        [
          "#{date_column} >= ? AND cost_type_id = ?",
          date, @rate.cost_type_id
        ]
      end
    end
    
    def conditions_between(date1, date2 = nil, date_column = :spent_on)
      # if the second date is not given, return all entries
      # with a spent_on after the given date
      return conditions_after(date1 || date2, date_column) if date1.nil? || date2.nil?
      
      (date1, date2) = order_dates(date1, date2)
      
      # return conditions for all entries between date1 and date2 - 1 day
      if @rate.is_a?(HourlyRate)
        { date_column => date1..(date2 - 1),
          :user_id => @rate.user_id,
          :project_id => @rate.project_id
        }
      else
        { date_column => date1..(date2 - 1),
          :cost_type_id => @rate.cost_type_id,
        }
      end
    end
    
    def find_entries(date1, date2 = nil)
      if @rate.is_a?(HourlyRate)
        TimeEntry.find(:all, :conditions => conditions_between(date1, date2), :include => :rate)
      else
        CostEntry.find(:all, :conditions => conditions_between(date1, date2), :include => :rate)
      end
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
    
    def count_rates(date1, date2 = nil)
      (@rate.class).count(:conditions => conditions_between(date1, date2, :valid_from))
    end
    
    def orphaned_child_entries(date1, date2 = nil)
      # This method returns all entries in child projects without an explicit
      # rate or with a rate id of rate_id between date1 and date2
      # i.e. the ones with an assigned default rate or without a rate
      return [] unless @rate.is_a?(HourlyRate)
      
      (date1, date2) = order_dates(date1, date2)
      
      # This gets an array of all the ids of the DefaultHourlyRates
      default_rates = DefaultHourlyRate.find(:all, :select => :id).inject([]){|r,d|r<<d.id}
      
      if date1.nil? || date2.nil?
        # we have only one date, query >=
        conditions = [
          "user_id = ? AND project_id IN (?) AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on >= ?",
          @rate.user_id, @rate.project.descendants, default_rates, date1 || date2
        ]
      else
        # we have two dates, query between
        conditions = [
          "user_id = ? AND project_id IN (?) AND (rate_id IN (?) OR rate_id IS NULL) AND spent_on BETWEEN ? AND ?",
          @rate.user_id, @rate.project.descendants, default_rates, date1, date2
        ]
      end
      
      TimeEntry.find(:all, :conditions => conditions, :include => :rate)
    end
    
    def child_entries(date1, date2 = nil)
      # This method returns all entries in child projects without an explicit
      # rate or with a rate id of rate_id between date1 and date2
      # i.e. the ones with an assigned default rate or without a rate
      return [] unless @rate.is_a?(HourlyRate)
      
      (date1, date2) = order_dates(date1, date2)

      if date1.nil? || date2.nil?
        # we have only one date, query >=
        conditions = [
          "user_id = ? AND project_id IN (?) AND rate_id = ? AND spent_on >= ?",
          @rate.user_id, @rate.project.descendants, @rate.id, date1 || date2
        ]
      else
        # we have two dates, query between
        conditions = [
          "user_id = ? AND project_id IN (?) AND rate_id  = ? AND spent_on BETWEEN ? AND ?",
          @rate.user_id, @rate.project.descendants, @rate.id, date1, date2
        ]
      end
      
      TimeEntry.find(:all, :conditions => conditions, :include => :rate)
    end
  end
  
  def after_create(rate)
    o = Methods.new(rate)

    next_rate = rate.next
    # get entries from the current project
    entries = o.find_entries(rate.valid_from, (next_rate.valid_from if next_rate))
    
    # and entries from subprojects that need updating (only applies to hourly_rates)
    entries += o.orphaned_child_entries(rate.valid_from, (next_rate.valid_from if next_rate))
    
    o.update_entries(entries)
  end
  
  def after_update(rate)
    o = Methods.new(rate)
    
    unless rate.valid_from_changed?
      # We have not moved a rate, maybe just changed the rate value
      
      return unless rate.rate_changed?
      # Only the rate value was changed so just update the currently assigned entries
      return after_create(rate)
    end
    
    # We have definitely moved the rate
    if o.count_rates(rate.valid_from_was, rate.valid_from) > 0
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
      
      # get entries from the current project
      entries = o.find_entries(rate.valid_from_was, rate.valid_from)
      # and entries from subprojects that need updating (only applies to hourly_rates)
      entries += o.child_entries(rate.valid_from_was, rate.valid_from)
            
      o.update_entries(entries, (rate.valid_from_was < rate.valid_from) ? rate.previous : rate)
    end
  end
  
  def after_destroy(rate)
    entry_class = rate.is_a?(HourlyRate) ? TimeEntry : CostEntry
    entry_class.find(:all, :conditions => {:rate_id => rate.id}).each{|e| e.update_costs!}
  end
end