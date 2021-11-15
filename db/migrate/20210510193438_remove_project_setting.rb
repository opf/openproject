class RemoveProjectSetting < ActiveRecord::Migration[6.1]
  def up
    Project.where(name: 'sequential_project_identifiers').delete_all
  end

  def down
    # Nothing to do
  end
end
