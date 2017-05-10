class AddProjectState < ActiveRecord::Migration[5.0]
  def change
    add_column :projects, :state, :integer
  end
end
