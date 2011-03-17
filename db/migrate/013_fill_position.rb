class FillPosition < ActiveRecord::Migration
  def self.up
    pos = execute "select project_id, max(position) from issues where parent_id is null group by project_id"
    pos.each do |row|
      project_id = row[0].to_i
      position = row[1].to_i

      Story.find(:all, :conditions => ["project_id = ? and parent_id is null and position is null", project_id], :order => "created_on").each do |story|
        position += 1

        story.position = position
        story.save
      end
    end
  end

  def self.down
    #pass
  end
end
