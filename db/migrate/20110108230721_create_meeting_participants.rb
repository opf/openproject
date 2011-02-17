class CreateMeetingParticipants < ActiveRecord::Migration
  def self.up
    create_table :meeting_participants do |t|
      t.column :user_id, :integer
      t.column :meeting_id, :integer
      t.column :meeting_role_id, :integer
      t.column :email, :string
      t.column :name, :string
      t.column :invited, :boolean
      t.column :attended, :boolean
      
      t.timestamps
    end
  end

  def self.down
    drop_table :meeting_participants
  end
end
