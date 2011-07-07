module ProjectIssueStatus
  module IssueModelPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

      end
    end

    module InstanceMethods
      def done?
        self.project.issue_statuses.include?(self.status)
      end
    end
  end
end

Issue.send(:include, ProjectIssueStatus::IssueModelPatch)