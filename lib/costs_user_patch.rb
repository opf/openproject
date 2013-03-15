require_dependency 'project'

require_dependency 'principal'
require_dependency 'user'

module CostsUserPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      has_many :rates, :class_name => 'HourlyRate'
      has_many :default_rates, :class_name => 'DefaultHourlyRate'

      before_save :save_rates
    end
  end

  module InstanceMethods
    def allowed_to_condition_with_project_id(permission, projects = nil)
      ids = Project.all(:select => :id,
                        :conditions => Project.allowed_to_condition(self, permission, :project => projects)).map(&:id)

      ids.empty? ?
        "1=0" :
        "(#{Project.table_name}.id in (#{ids.join(", ")}))"
    end

    def current_rate(project = nil, include_default = true)
      rate_at(Date.today, project, include_default)
    end

    # kept for backwards compatibility
    def rate_at(date, project = nil, include_default = true)
      ::HourlyRate.at_date_for_user_in_project(date, self.id, project, include_default)
    end

    def current_default_rate()
      ::DefaultHourlyRate.at_for_user(Date.today, self.id)
    end

    # kept for backwards compatibility
    def default_rate_at(date)
      ::DefaultHourlyRate.at_for_user(date, self.id)
    end

    def add_rates(project, rate_attributes)
      # set project to nil to set the default rates

      return unless rate_attributes

      rate_attributes.each do |index, attributes|
        attributes[:rate] = Rate.clean_currency(attributes[:rate])

        if project.nil?
          default_rates.build(attributes)
        else
          attributes[:project] = project
          rates.build(attributes)
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
      (default_rates + rates).each do |rate|
        rate.save(false)
      end
    end


  private
    def update_rate(rate, rate_attributes, project_rate = true)
      attributes = rate_attributes[rate.id.to_s] if rate_attributes

      has_rate = false
      if attributes && attributes[:rate].present?
        attributes[:rate] = Rate.clean_currency(attributes[:rate])
        has_rate = true
      end

      if has_rate
        rate.attributes = attributes
      else
        project_rate ? rates.delete(rate) : default_rates.delete(rate)
      end
    end
  end
end

User.send(:include, CostsUserPatch)
