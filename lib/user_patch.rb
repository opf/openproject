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
      has_many :default_rates, :class_name => 'DefaultHourlyRate'
      
      after_update :save_rates
    end

  end

  module ClassMethods

  end

  module InstanceMethods
    def current_rate(project = nil, include_default = true)
      rate_at(Date.today, project, include_default)
    end
    
    def rate_at(date, project = nil, include_default = true)
      unless project.nil?
        project = Project.find(project) unless project.is_a?(Project)
      
        rate = HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id = ? and valid_from <= ?", id, project, date], :order => "valid_from DESC")
        # TODO: this is Redmine 0.8 specific. Sort by project.lft first if using redmine 0.9!
        rate ||= HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id in (?) and valid_from <= ?", id, project.ancestors, date], :order => "valid_from DESC")
      end
      rate ||= default_rate_at(date) if include_default
      rate
    end
    
    def current_default_rate()
      default_rate_at(Date.today)
    end

    def default_rate_at(date)
      DefaultHourlyRate.find(:first, :conditions => [ "user_id = ? and valid_from <= ?", id, date], :order => "valid_from DESC")
    end
    
    def add_rates(project, rate_attributes)
      # set project to nil to set the default rates
      
      return unless rate_attributes
      
      rate_attributes.each do |index, attributes|
        attributes[:rate] = Rate.clean_currency(attributes[:rate])
        
        if project.nil?
          default_rates.build(attributes) if attributes[:rate].to_f > 0
        else
          attributes[:project] = project
          rates.build(attributes) if attributes[:rate].to_f > 0
        end
      end
    end

    def set_existing_rates (project, rate_attributes)
      if project.nil?
        default_rates.reject(&:new_record?).each do |rate|
          update_rate(rate, rate_attributes, false)
        end
      else
        rates.reject{|r| r.new_record? || r.project_id != project.id}.each do |rate|
          update_rate(rate, rate_attributes, true)
        end
      end
    end
    
    def save_rates
      rates.each do |rate|
        rate.save(false)
      end
    end
    
    
  private
    def update_rate(rate, rate_attributes, project_rate = true)
      attributes = rate_attributes[rate.id.to_s] if rate_attributes

      has_rate = false
      if attributes && attributes[:rate]
        attributes[:rate] = Rate.clean_currency(attributes[:rate])
        has_rate = attributes[:rate].to_f > 0
      end

      if has_rate
        rate.attributes = attributes
      else
        project_rate ? rates.delete(rate) : default_rates.delete(rate)
      end
    end
  end
end
