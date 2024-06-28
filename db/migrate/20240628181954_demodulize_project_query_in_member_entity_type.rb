class DemodulizeProjectQueryInMemberEntityType < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE members SET entity_type = 'ProjectQuery' WHERE entity_type = 'Queries::Projects::ProjectQuery'"
  end

  def down
    execute "UPDATE members SET entity_type = 'Queries::Projects::ProjectQuery' WHERE entity_type = 'ProjectQuery'"
  end
end
