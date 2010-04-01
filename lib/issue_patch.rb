require_dependency 'issue'

module IssuePatch
    def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
            unloadable

            alias_method_chain :move_to_project_without_transaction, :autolink
            alias_method_chain :update_parent_attributes, :remaining_hours
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
            # a "true" task
            return true if self.tracker_id.class != NilClass and self.tracker_id == Task.tracker

            # a story that doubles as its only task
            return true if self.is_story? and self.descendants.length == 0

            # not a task
            return false
        end

        def story
            return Issue.find(:first,
                :conditions => [ "id = ? and tracker_id in (?)", self.root_id, Story.trackers.map { |t| t.to_s }.join(',') ])
        end

        def update_parent_attributes_with_remaining_hours
            update_parent_attributes_without_remaining_hours

            if parent_id && p = Issue.find_by_id(parent_id) 
                p.remaining_hours = p.leaves.sum(:remaining_hours).to_f
                p.save
            end
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
                    story = self.story
                    if not story.nil?
                        version = story.fixed_version_id.nil? ? 'NULL' : story.fixed_version_id.nil
                        connection.execute "update issues set tracker_id = #{Task.tracker}, fixed_version_id = #{version} where id = #{self.id}"
                    end
                end
            end
        end
    end
end
