class AddIndexForLatestMeetingActivity < ActiveRecord::Migration
  def change
    add_index :meetings, [:project_id, :updated_at]
  end
end
