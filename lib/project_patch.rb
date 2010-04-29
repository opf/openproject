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
    end

  end

  module ClassMethods

  end

  module InstanceMethods

  end
end
