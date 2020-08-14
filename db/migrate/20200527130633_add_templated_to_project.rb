class AddTemplatedToProject < ActiveRecord::Migration[6.0]
  def change
    add_column :projects, :templated, :boolean, default: false, null: false
  end
end
