desc 'Fix types after migration 011'

namespace :redmine do
  namespace :backlogs do
    task :fixup_types => :environment do
      story_types = Story.types
      story_type_id = story_types[0]
      task_type_id = Task.type

      projects = EnabledModule.find(:all,
                                  :conditions => ["enabled_modules.name = 'backlogs' and status = ?", Project::STATUS_ACTIVE],
                                  :include => :project,
                                  :joins => :project).collect { |mod| mod.project }

      story_type = story_type_id ?  type.find_by_id(story_type_id) : nil
      task_type = task_type_id ?  type.find_by_id(task_type_id) : nil

      raise 'No story type configured' unless story_type_id && story_type
      raise 'No task type configured' unless task_type_id && task_type
      raise 'No projects are backlogs-enabled' unless projects.size > 0

      puts "Story type: #{story_type.name} (#{story_type_id})"
      puts "Task type: #{task_type.name} (#{task_type_id})"

      projects.each do |project|
        WorkPackage.find(:all, :conditions => ["not parent_id is null and project_id = #{project.id}"]).each do |work_package|
          if work_package.type_id != task_type_id
            puts "Making work_package #{work_package.subject} (#{work_package.id}) into a task"
            work_package.type_id = task_type_id
            work_package.save!
          end

          parent = work_package.parent
          if !story_types.include?(parent.type_id)
            puts "Making work_package #{parent.subject} (#{parent.id}, #{parent.type.name}) into a story (#{story_type.name})"
            parent.type_id = story_type_id
            parent.save!
          end
        end
      end

    end
  end
end
