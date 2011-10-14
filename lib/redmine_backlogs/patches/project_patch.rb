require_dependency 'project'

module RedmineBacklogs::Patches::ProjectPatch
  def self.included(base)
    base.class_eval do
      unloadable

      has_and_belongs_to_many :issue_statuses, :join_table => :issue_done_statuses_for_project
    end
  end
end

Project.send(:include, RedmineBacklogs::Patches::ProjectPatch)
