class Story < Issue
    unloadable

    acts_as_list :scope => 'coalesce(cast(issues.fixed_version_id as char), \'\') = \'#{fixed_version_id}\' AND issues.parent_id is NULL'

    named_scope :product_backlog, lambda { |project|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and project_id = ? and tracker_id = ? and fixed_version_id is NULL",
                project.id, Setting.plugin_redmine_backlogs[:story_tracker]
                ]
        }
    }

    named_scope :sprint_backlog, lambda { |sprint|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and tracker_id = ? and fixed_version_id = ?",
                Setting.plugin_redmine_backlogs[:story_tracker], sprint.id
                ]
        }
    }

    def self.is_story(id)
        return ! Story.find(:id => id, parent_id => nil, tracker_id => Setting.plugin_redmine_backlogs[:story_tracker]).nil?
    end

    def abbreviated_subject
        cap = 60
        subject = read_attribute(:subject)
        if subject.length > cap
            return subject[0,cap - 3] + '...'
        else
            return subject
        end
    end
end
