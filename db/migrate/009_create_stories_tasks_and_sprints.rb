class CreateStoriesTasksAndSprints < ActiveRecord::Migration
  def self.up
    add_column :issues, :position, :integer
    add_column :issues, :story_points, :integer
    add_column :issues, :remaining_hours, :float

    add_column :versions, :start_date, :datetime, :null => true

    Story.reset_column_information

    stories = Story.all(
        :joins => 'join enumerations on issues.priority_id = enumerations.id',
        :order => 'enumerations.position desc, issues.id',
        :readonly => false
        )

    stories.each_with_index { |story, pos|
        story.update_attribute(:position, pos + 1)
    }

    begin
        res = execute "select issue_id, version_id, position, version_id, parent_id, points from items left join backlogs on backlog_id = backlogs.id"
        res.each { |row|
            issue, version, position, parent, points = row

            if not version.nil? and version != 0
                execute "update issues set fixed_version_id = #{version} where id = #{issue}"
            end

            execute "update issues set position = #{position} where id = #{issue}"

            if not points.nil? and points != 0
                execute "update issues set story_points = #{points} where id = #{issue}"
            end

            if not parent.nil? and parent != 0
                execute "update issues set parent_id = (select issue_id from items where id = #{parent})"
            end
        }
    rescue
        #pass
    end

    begin
        res = execute "select version_id, start_date, is_closed from backlogs"
        res.each { |row|
            version, start_date, is_closed = row
            status = is_closed ? 'closed' : 'open'

            if not start_date.nil?
                execute "update versions set start_date = '#{start_date}' where id = #{version}"
            end
            execute "update versions set status = '#{status}' where id = #{version}"
        }
    rescue
        #pass
    end

    Issue.rebuild!
  end

  def self.down
    #pass
  end
end
