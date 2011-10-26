require_dependency 'issue_status'

module RedmineBacklogs::Patches::IssueStatusPatch
  def self.included(base)
    base.class_eval do
      unloadable

      include InstanceMethods
    end
  end

  module InstanceMethods
    def is_done?(project)
      project.issue_statuses.include?(self)
    end
  end
end

IssueStatus.send(:include, RedmineBacklogs::Patches::IssueStatusPatch)
