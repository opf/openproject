module ProjectIssueStatus
  module IssueStatusPatch 
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
      end
    end

    module InstanceMethods
      def is_done?(project)
        project.issue_statuses.include?(self)
      end
    end
  end
end

IssueStatus.send(:include, ProjectIssueStatus::IssueStatusPatch)
