require_dependency 'project'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Cost Object
module ProjectPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable
      
      has_many :cost_objects
      has_many :rates, :class_name => 'HourlyRate'
      
      has_many :member_groups, :class_name => 'Member', 
                               :include => :principal,
                               :conditions => "#{Principal.table_name}.type='Group'"
      has_many :groups, :through => :member_groups, :source => :principal
      
      unless singleton_methods.include? "allowed_to_condition_without_inheritance"
        class << self
          alias_method_chain :allowed_to_condition, :inheritance
        end
      end
      
    end

  end

  module ClassMethods
    def allowed_to_condition_with_inheritance(user, permission, options={})
      if options[:project]
        projects = [options[:project]]
      else
        projects = Project.active.all(:conditions => Project.visible_by(user))
      end

      projects = projects.collect(&:children).flatten.uniq if options[:with_subprojects]
      
      user.allowed_for(permission, projects)
    end

  end

  module InstanceMethods
  end
end
