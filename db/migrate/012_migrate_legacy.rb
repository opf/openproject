class MigrateLegacy < ActiveRecord::Migration
  def self.normalize_value(v, t)
    return nil if v.class == NilClass

    case t
      when :int
        return Integer(v)

      when :bool
        if [TrueClass, FalseClass].include?(v.class)
          return v
        else
          return ! (['', '0'].include?("#{v}"))
        end

      else
        return v
    end
  end

  def self.row(r, t)
    normalized = []
    r.each_with_index{|v, i|
      normalized << MigrateLegacy.normalize_value(v, t[i])
    }
    return normalized
  end

  def self.up
    begin
      execute "select count(*) from backlogs"
      legacy = true
    rescue
      legacy = false
    end

    adapter = ActiveRecord::Base.connection.instance_variable_get("@config")[:adapter].downcase

    ActiveRecord::Base.connection.commit_db_transaction unless adapter.include?('sqlite')

    if legacy
      Story.reset_column_information
      Issue.reset_column_information
      Task.reset_column_information

      if Story.trackers.nil? || Story.trackers.size == 0 || Task.tracker.nil?
        raise "Please configure the Backlogs Story and Task trackers before migrating.

        You do this by starting Redmine and going to \"Administration -> Plugins -> Redmine Scrum Plugin -> Configure\"
        and setting up the Task tracker and one or more Story trackers.
        You might have to go to  \"Administration -> Trackers\" first
        and create new trackers for this purpose. After doing this, stop
        redmine and re-run this migration."
      end

      trackers = {}
      
      # find story/task trackers per project
      execute("
          select projects.id as project_id, pt.tracker_id as tracker_id
          from projects
          left join projects_trackers pt on pt.project_id = projects.id").each { |row|

        project_id, tracker_id = MigrateLegacy.row(row, [:int, :int])

        trackers[project_id] ||= {}
        trackers[project_id][:story] = tracker_id if Story.trackers.include?(tracker_id)
        trackers[project_id][:task] = tracker_id if Task.tracker == tracker_id
      }

      # close existing transactions and turn on autocommit
      ActiveRecord::Base.connection.commit_db_transaction unless adapter.include?('sqlite')

      say_with_time "Migrating Backlogs data..." do
        bottom = 0
        execute("select coalesce(max(position), 0) from items").each { |row| 
          bottom = row[0].to_i
        }
        bottom += 1

        connection = ActiveRecord::Base.connection

        stories = execute "
          select story.issue_id, story.points, versions.id, issues.project_id
          from items story
          join issues on issues.id = story.issue_id
          left join items parent on parent.id = story.parent_id and story.parent_id <> 0
          left join backlogs sprint on story.backlog_id = sprint.id and sprint.id <> 0
          left join versions on versions.id = sprint.version_id and sprint.version_id <> 0
          where parent.id is null
          order by coalesce(story.position, #{bottom}) desc, story.created_at desc"

        stories.each { |row|
          id, points, sprint, project = MigrateLegacy.row(row, [:int, :int, :int, :int])

          say "Updating story #{id}"
          story = Story.find(id)

          if ! Story.trackers.include?(story.tracker_id)
            raise "Project #{project} does not have a story tracker configured" unless trackers[project][:story]
            story.tracker_id = trackers[project][:story]
            story.save!
          end

          story.fixed_version_id = sprint
          story.story_points = points
          story.save!

          # because we're inserting the stories last-first, this
          # position gets shifted down 1 spot each time, yielding a
          # neatly compacted position list
          story.insert_at 1
        }

        tasks = execute "
          select task.issue_id, versions.id, parent.issue_id, task_issue.project_id
          from items task
          join issues task_issue on task_issue.id = task.issue_id
          join items parent on parent.id = task.parent_id and task.parent_id <> 0
          join issues parent_issue on parent_issue.id = parent.issue_id
          left join backlogs sprint on task.backlog_id = sprint.id and sprint.id <> 0
          left join versions on versions.id = sprint.version_id and sprint.version_id <> 0
          order by coalesce(task.position, #{bottom}), task.created_at"

        tasks.each { |row|
          id, sprint, parent_id, project = MigrateLegacy.row(row, [:int, :int, :int, :int])

          say "Updating task #{id}"

          task = Task.find(id)

          if ! Task.tracker == task.tracker_id
            raise "Project #{project} does not have a task tracker configured" unless trackers[project][:task]
            task.tracker_id = trackers[project][:task]
            task.save!
          end

          # because we're inserting the tasks first-last, adding it to
          # the story will yield the correct order
          task.fixed_version_id = sprint
          task.parent_issue_id = parent_id
          task.save!
        }

        res = execute "select version_id, start_date, is_closed from backlogs"
        res.each { |row|
          version, start_date, is_closed = MigrateLegacy.row(row, [:int, :string, :bool])

          status = connection.quote(is_closed ? 'closed' : 'open')
          version = connection.quote(version == 0 ? nil : version)
          start_date = connection.quote(start_date)

          execute "update versions set status = #{status}, sprint_start_date = #{start_date} where id = #{version}"
        }
      end

      execute %{
        insert into burndown_days (version_id, points_committed, points_accepted, created_at)
        select version_id, scope, done, backlog_chart_data.created_at
        from backlogs
        join backlog_chart_data on backlogs.id = backlog_id
        }
      ActiveRecord::Base.connection.commit_db_transaction unless adapter.include?('sqlite')

      drop_table :backlogs
      drop_table :items
    end

  end

  def self.down
    #pass
  end
end
