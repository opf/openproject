class CreateMeetingAgendaTops < ActiveRecord::Migration[5.1]
  def change
    create_table :meeting_agenda_tops do |t|
      t.references :meeting, foreign_key: true
      t.references :user, foreign_key: true
      t.string :title
      t.text :description
      t.integer :position
      t.integer :duration_in_minutes
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end