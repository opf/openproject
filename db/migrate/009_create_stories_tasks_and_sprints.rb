class CreateStoriesTasksAndSprints < ActiveRecord::Migration
  def self.up
    add_column :issues, :position, :integer
    add_column :issues, :story_points, :integer
    add_column :issues, :remaining_hours, :float

    add_column :versions, :sprint_start_date, :date, :null => true

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

            res = execute "select issue_id, version_id, position, version_id, parent_id, points from items left join backlogs on backlog_id = backlogs.id"
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
  end

  def self.down
    #pass
  end
end
