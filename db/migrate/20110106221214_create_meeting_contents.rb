class CreateMeetingContents < ActiveRecord::Migration
  def self.up
    create_table :meeting_contents do |t|
      t.column :type, :string
      t.column :meeting_id, :integer
      t.column :author_id, :integer
      t.column :text, :text
      t.column :comment, :string
      t.column :version, :integer
    end
  end

  def self.down
    drop_table :meeting_contents
  end
end
