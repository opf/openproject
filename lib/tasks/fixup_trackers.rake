desc 'Fix trackers after migration 011'

namespace :redmine do
  namespace :backlogs do
    task :fixup_trackers => :environment do
      story_trackers = Story.trackers
      story_tracker_id = story_trackers[0]
      task_tracker_id = Task.tracker

      projects = EnabledModule.find(:all,
                                  :conditions => ["enabled_modules.name = 'backlogs' and status = ?", Project::STATUS_ACTIVE],
                                  :include => :project,
                                  :joins => :project).collect { |mod| mod.project }

      story_tracker = story_tracker_id ?  Tracker.find_by_id(story_tracker_id) : nil
      task_tracker = task_tracker_id ?  Tracker.find_by_id(task_tracker_id) : nil

      raise 'No story tracker configured' unless story_tracker_id && story_tracker
      raise 'No task tracker configured' unless task_tracker_id && task_tracker
      raise 'No projects are backlogs-enabled' unless projects.size > 0

      puts "Story tracker: #{story_tracker.name} (#{story_tracker_id})"
      puts "Task tracker: #{task_tracker.name} (#{task_tracker_id})"

      projects.each do |project|
        Issue.find(:all, :conditions => ["not parent_id is null and project_id = #{project.id}"]).each do |issue|
          if issue.tracker_id != task_tracker_id
            puts "Making issue #{issue.subject} (#{issue.id}) into a task"
            issue.tracker_id = task_tracker_id
            issue.save!
          end

          parent = issue.parent
          if !story_trackers.include?(parent.tracker_id)
            puts "Making issue #{parent.subject} (#{parent.id}, #{parent.tracker.name}) into a story (#{story_tracker.name})"
            parent.tracker_id = story_tracker_id
            parent.save!
          end
        end
      end

    end
  end
end
