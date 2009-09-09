# TODO: which require statement to use here? require_dependency breaks stuff
#require 'user'

# Patches Redmine's Users dynamically.
module UserPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      has_many :rates, :class_name => 'HourlyRate'
      after_update :save_rates
    end

  end

  module ClassMethods

  end

  module InstanceMethods
    def current_rate(project_id)
      rate_at(Date.today, project_id)
    end
    
    def rate_at(date, project_id)
      HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id = ? and valid_from <= ?", id, project_id, date], :order => "valid_from DESC")
    end
    
    def new_rate_attributes=(rate_attributes)
      rate_attributes.each do |index, attributes|
        attributes[:rate] = Rate.clean_currency(attributes[:rate])
        rates.build(attributes) if attributes[:rate].to_f > 0
      end
    end

    def existing_rate_attributes=(rate_attributes)
      rates.reject(&:new_record?).each do |rate|
        attributes = rate_attributes[rate.id.to_s]

        has_rate = false
        if attributes && attributes[:rate]
          attributes[:rate] = Rate.clean_currency(attributes[:rate])
          has_rate = attributes[:rate].to_f > 0
        end

        if has_rate
          rate.attributes = attributes
        else
          rates.delete(rate)
        end
      end
    end
    
    def save_rates
      rates.each do |rate|
        rate.save(false)
      end
    end
    
  end
end
