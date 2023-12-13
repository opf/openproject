class CreateMeetingAgendaItems < ActiveRecord::Migration[5.1]
  def change
    create_table :meeting_agenda_items do |t|
      t.references :meeting, foreign_key: true
      t.references :author, foreign_key: { to_table: :users }
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
