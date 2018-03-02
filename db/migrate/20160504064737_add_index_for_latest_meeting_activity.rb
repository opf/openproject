class AddIndexForLatestMeetingActivity < ActiveRecord::Migration[5.0]
  def change
    add_index :meetings, [:project_id, :updated_at]
  end
end
