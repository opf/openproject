require_dependency 'issue'

module IssuePatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
            unloadable

            alias_method_chain :move_to_project_without_transaction, :autolink
        end
    end

    module ClassMethods
    end

    module InstanceMethods
        def move_to_project_without_transaction_with_autolink(new_project, new_tracker = nil, options = {})
            newissue = move_to_project_without_transaction_without_autolink(new_project, new_tracker, options)

            story_tracker = Integer(Setting.plugin_redmine_backlogs[:story_tracker])
            if self.project_id == newissue.project_id and self.tracker_id == story_tracker and newissue.tracker_id == story_tracker and self.id != newissue.id
                relation = IssueRelation.new :relation_type => IssueRelation::TYPE_RELATES
                relation.issue_from = self
                relation.issue_to = newissue
                relation.save
            end
        end
    end
end
