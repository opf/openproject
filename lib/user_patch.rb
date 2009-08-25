require_dependency 'user'

# Patches Redmine's Users dynamically.
module UserPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      has_many :rates, :class_name => 'HourlyRate'
      
      def current_rate(project_id)
        HourlyRate.find(:first, :conditions => [ "user_id = ? and project_id = ? and valid_from <= ?", id, project_id, Date.today], :order => "valid_from DESC")
      end
    end

  end

  module ClassMethods

  end

  module InstanceMethods

  end
end
