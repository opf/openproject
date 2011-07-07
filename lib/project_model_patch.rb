module ProjectIssueStatus
  module ProjectModelPatch
    def self.included(base)
      base.class_eval do
        base.send(:include, InstanceMethods)
          has_and_belongs_to_many :issue_statuses, :join_table => :issue_done_statuses_for_project
      end
    end

    module InstanceMethods
    end
  end
end

Project.send(:include, ProjectIssueStatus::ProjectModelPatch)