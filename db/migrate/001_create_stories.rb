class CreateStories < ActiveRecord::Migration
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

    Issue.rebuild!
  end

  def self.down
    #pass
  end
end
