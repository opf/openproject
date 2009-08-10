require_dependency 'project'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Deliverable
module ProjectPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      has_many :deliverables
    end

  end

  module ClassMethods

  end

  module InstanceMethods

  end
end
