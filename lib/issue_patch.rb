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

            if not Setting.plugin_redmine_backlogs[:story_tracker].nil?
                story_tracker = Integer(Setting.plugin_redmine_backlogs[:story_tracker])
                if self.project_id == newissue.project_id and self.tracker_id == story_tracker and newissue.tracker_id == story_tracker and self.id != newissue.id
                    relation = IssueRelation.new :relation_type => IssueRelation::TYPE_RELATES
                    relation.issue_from = self
                    relation.issue_to = newissue
                    relation.save
                end
            end

            return newissue
        end

        def task_follows_story
            ## automatically sets the tracker to the task tracker for
            ## any descendant of story, and follow the version_id
            ## Normally one of the _before_save hooks ought to take
            ## care of this, but appearantly neither root_id nor
            ## parent_id are set at that point

            story_tracker = Setting.plugin_redmine_backlogs[:story_tracker]
            task_tracker = Setting.plugin_redmine_backlogs[:task_tracker]

            if not story_tracker.nil? and not task_tracker.nil?
                story_tracker = Integer(story_tracker)
                task_tracker = Integer(task_tracker)

                if self.parent_id.nil?
                    if self.tracker_id == story_tracker
                        # raw sql here because it's efficient and not
                        # doing so causes an update loop when Issue calls
                        # update_parent
                        version = self.fixed_version_id.nil? ? 'NULL' : self.fixed_version_id
                        sql = ActiveRecord::Base.connection()
                        sql.execute "update issues set tracker_id = #{task_tracker}, fixed_version_id = #{version} where lft > #{self.lft} and lft < #{self.rgt} and rgt > #{self.lft} and rgt < #{self.rgt}"
                    end
                else
                    story = Issue.find(:id => self.root_id, :tracker_id => story_tracker)
                    if not story.nil?
                        version = story.fixed_version_id.nil? ? 'NULL' : story.fixed_version_id.nil
                        sql = ActiveRecord::Base.connection()
                        sql.execute "update issues set tracker_id = #{task_tracker}, fixed_version_id = #{version} where id = #{self.id}"
                    end
                end
            end
        end
    end
end
