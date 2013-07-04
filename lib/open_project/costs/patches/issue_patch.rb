require 'issue'

module OpenProject::Costs::Patches::IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class
    base.class_eval do
      unloadable

      belongs_to :cost_object
      has_many :cost_entries, :foreign_key => :work_package_id, :dependent => :delete_all
    end
  end

  module ClassMethods

  end

  module InstanceMethods

  end
end

Issue.send(:include, OpenProject::Costs::Patches::IssuePatch)
