class CreateStoriesTasksSprintsAndBurndown < ActiveRecord::Migration
    def self.up
        if Story.trackers.nil? || Story.trackers.size == 0 || Task.Tracker.nil?
          raise "Please configure the Backlogs Story and Task trackers before migrating"
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

        stories = Story.all(
            :joins => 'join enumerations on issues.priority_id = enumerations.id',
            :order => 'enumerations.position desc, issues.id',
            :readonly => false
        )

        stories.each_with_index { |story, pos|
            story.update_attribute(:position, pos + 1)
        }

        # close existing transactions and turn on autocommit
        ActiveRecord::Base.connection.commit_db_transaction

        begin
            execute "select count(*) from backlogs"
            backlogs_present = true
        rescue
            backlogs_present = false
        end

        if backlogs_present
            say_with_time "Migrating Backlogs data..." do
                connection = ActiveRecord::Base.connection

                res = execute "select issue_id, version_id, position, parent_id, points from items left join backlogs on backlog_id = backlogs.id"
                res.each { |row|
                    issue, version, position, parent, points = row
                    issue = connection.quote(issue)
                    version = connection.quote(version == 0 ? nil : version)
                    position = connection.quote(position)
                    parent = connection.quote(parent == 0 ? nil : parent)
                    points = connection.quote(points == 0 ? nil : points)

                    execute "update issues set fixed_version_id = #{version} where id = #{issue}"
                    execute "update issues set position = #{position} where id = #{issue}"
                    execute "update issues set story_points = #{points} where id = #{issue}"
                    execute "update issues set parent_id = (select issue_id from items where id = #{parent})"
                    
                    if parent_id and parent_id != 0
                      execute "update issues set tracker_id = #{task_tracker}, root_id = parent_id where id = #{issue}"
                    else
                      execute "update issues set tracker_id = #{story_tracker} where id = #{issue}"
                    end
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

        say_with_time "Rebuilding issues tree..." do
            # force rebuild
            execute "update issues set lft = NULL, rgt = NULL"
            Issue.reset_column_information
            Issue.rebuild!
        end

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
