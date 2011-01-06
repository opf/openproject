class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.column :title, :string
      t.column :author_id, :integer
      t.column :location, :string
      t.column :time, :datetime
    end
  end

  def self.down
    drop_table :meetings
  end
end
