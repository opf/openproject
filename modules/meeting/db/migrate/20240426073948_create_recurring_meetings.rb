class CreateRecurringMeetings < ActiveRecord::Migration[7.1]
  def change
    create_table :recurring_meetings do |t|
      t.text :title
      t.text :schedule
      t.belongs_to :project, foreign_key: true, index: true
      t.belongs_to :author, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_reference :meetings, :recurring_meeting_id, index: true
    add_column :meetings, :template, :boolean, default: false, null: false
  end
end
