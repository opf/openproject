class FillPosition < ActiveRecord::Migration
  def self.up
    pos = execute "select project_id, max(position) from issues where parent_id is null group by project_id"
    pos.each do |row|
      project_id, position = row
      position = position.to_i

      stories = execute "select id from issues where project_id = #{project_id} and parent_id is null and position is null order by created_on"
      stories.each do |id|
        position += 1
        execute "update issues set position = #{position} where id = #{id}"
      end
    end
  end

  def self.down
    #pass
  end
end
