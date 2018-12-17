class AddReadOnlyToStatuses < ActiveRecord::Migration[5.1]
  def change
    add_column :statuses, :is_readonly, :boolean, default: false
  end
end
