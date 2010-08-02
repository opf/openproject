class CreateStoriesTasksSprintsAndBurndown < ActiveRecord::Migration
  def self.up
    if Story.trackers.nil? || Story.trackers.size == 0 || Task.tracker.nil?
      raise "Please configure the Backlogs Story and Task trackers before migrating.

      You do this by starting Redmine and going to \"Administration -> Plugins -> Redmine Scrum Plugin -> Configure\"
      and setting up the Task tracker and one or more Story trackers.
      You might have to go to  \"Administration -> Trackers\" first
      and create new trackers for this purpose. After doing this, stop
      redmine and re-run this migration."
    end

    task_tracker = Task.tracker
    story_tracker = Story.trackers[0]

    add_column :issues, :position, :integer
    add_column :issues, :story_points, :integer
    add_column :issues, :remaining_hours, :float

    add_column :versions, :sprint_start_date, :date, :null => true

    create_table :burndown_days do |t|
      t.column :points_committed, :integer, :null => false, :default => 0
      t.column :points_accepted, :integer, :null => false, :default => 0
      t.column :points_resolved, :integer, :null => false, :default => 0
      t.column :remaining_hours, :float, :null => false, :default => 0

      t.column :version_id, :integer, :null => false
      t.timestamps
    end

    add_index :burndown_days, :version_id

    Story.reset_column_information
    Issue.reset_column_information
    Task.reset_column_information

    # close existing transactions and turn on autocommit
    ActiveRecord::Base.connection.commit_db_transaction

    begin
      execute "select count(*) from backlogs"
      backlogs_present = true
    rescue
      backlogs_present = false
    end

    bottom = 0
    execute("select coalesce(max(position), 0) from items").each { |row| 
      bottom = row[0].to_i
    }
    bottom += 1

    if backlogs_present
      say_with_time "Migrating Backlogs data..." do
        connection = ActiveRecord::Base.connection

        stories = execute "
          select story.issue_id, story.points, sprint.version_id
          from items story
          join issues on issues.id = story.issue_id
          left join items parent on parent.id = story.parent_id and story.parent_id <> 0
          left join backlogs sprint on story.backlog_id = sprint.id and sprint.id <> 0
          where parent.id is null
          order by coalesce(story.position, #{bottom}) desc, story.created_at desc"

        stories.each { |row|
          id, points, sprint = row

          story = Story.find(id)

          story.update_attributes(
            :tracker_id => story_tracker,
            :fixed_version_id => sprint,
            :story_points => points
          )

          # because we're inserting the stories last-first, this
          # position gets shifted down 1 spot each time, yielding a
          # neatly compacted position list
          story.insert_at 1
        }

        tasks = execute "
          select task.issue_id, sprint.version_id, parent.issue_id
          from items task
          join issues task_issue on task_issue.id = task.issue_id
          join items parent on parent.id = task.parent_id and task.parent_id <> 0
          join issues parent_issue on parent_issue.id = parent.issue_id
          left join backlogs sprint on task.backlog_id = sprint.id and sprint.id <> 0
          order by coalesce(task.position, #{bottom}) desc, task.created_at desc"

        tasks.each { |row|
          id, sprint, parent_id = row

          task = Task.find(id)

          task.update_attributes(
            :tracker_id => task_tracker,
            :fixed_version_id => sprint
          )

          # this must be done before insert_at, because task position
          # (see below) is scoped to the parent issue
          task.move_to_child_of parent_id

          # because we're inserting the tasks last-first, this
          # position gets shifted down 1 spot each time, yielding a
          # neatly compacted position list
          task.insert_at 1
        }

        res = execute "select version_id, start_date, is_closed from backlogs"
        res.each { |row|
          version, start_date, is_closed = row
          status = connection.quote(is_closed ? 'closed' : 'open')
          version = connection.quote(version == 0 ? nil : version)
          start_date = connection.quote(start_date)

          execute "update versions set status = #{status}, sprint_start_date = #{start_date} where id = #{version}"
        }
      end
    end

    # RM core started needing this... I'm not agreeing, but I need to
    # get the migration working
    execute "update issues set start_date = NULL where due_date < start_date"

    begin
      execute "select count(*) from backlog_chart_data"
      bcd = true
    rescue
      bcd = false
    end

    if bcd
      execute %{
        insert into burndown_days (version_id, points_committed, points_accepted, created_at)
        select version_id, scope, done, backlog_chart_data.created_at
        from backlogs
        join backlog_chart_data on backlogs.id = backlog_id
        }
    end

    drop_table 'items'
    drop_table 'backlogs'
  end

  def self.down
    #pass
  end
end
