require_dependency 'status'

module OpenProject::Backlogs::Patches::StatusPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods
    end
  end

  module InstanceMethods
    def is_done?(project)
      project.done_statuses.include?(self)
    end
  end
end

Status.send(:include, OpenProject::Backlogs::Patches::StatusPatch)
