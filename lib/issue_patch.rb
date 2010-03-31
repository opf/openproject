require_dependency 'issue'

module IssuePatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
            unloadable

            alias_method_chain :move_to_project_without_transaction, :autolink
            after_save    :task_follows_story
        end
    end

    module ClassMethods
    end

    module InstanceMethods
        def move_to_project_without_transaction_with_autolink(new_project, new_tracker = nil, options = {})
            newissue = move_to_project_without_transaction_without_autolink(new_project, new_tracker, options)

            if self.project_id == newissue.project_id and self.is_story? and newissue.is_story? and self.id != newissue.id
                relation = IssueRelation.new :relation_type => IssueRelation::TYPE_RELATES
                relation.issue_from = self
                relation.issue_to = newissue
                relation.save
            end

            return newissue
        end

        def is_story?
            return (Story.trackers.include?(self.tracker_id) and self.root?)
        end

        def is_task?
            return (self.tracker_id.class != NilClass and self.tracker_id == Task.tracker and not self.root?)
        end

        def task_follows_story
            ## automatically sets the tracker to the task tracker for
            ## any descendant of story, and follow the version_id
            ## Normally one of the _before_save hooks ought to take
            ## care of this, but appearantly neither root_id nor
            ## parent_id are set at that point

            if self.is_story?
                # raw sql here because it's efficient and not
                # doing so causes an update loop when Issue calls
                # update_parent
                if not Task.tracker.nil?
                    version = self.fixed_version_id.nil? ? 'NULL' : self.fixed_version_id
                    connection.execute "update issues set tracker_id = #{Task.tracker}, fixed_version_id = #{version} where lft > #{self.lft} and lft < #{self.rgt} and rgt > #{self.lft} and rgt < #{self.rgt}"
                end
            elsif not Task.tracker.nil?
                begin
                    story = Issue.find(self.root_id)
                    if story.is_story?
                        version = story.fixed_version_id.nil? ? 'NULL' : story.fixed_version_id.nil
                        connection.execute "update issues set tracker_id = #{Task.tracker}, fixed_version_id = #{version} where id = #{self.id}"
                    end
                end
            end
        end
    end
end
