class CreateMeetingSections < ActiveRecord::Migration[7.1]
  def up
    create_table :meeting_sections do |t|
      t.integer :position
      t.string :title
      t.references :meeting, null: false, foreign_key: true

      t.timestamps
    end

    add_reference :meeting_agenda_items, :meeting_section

    create_and_assign_default_section
  end

  def down
    remove_reference :meeting_agenda_items, :meeting_section
    drop_table :meeting_sections
    # TODO: positions of agenda items are now not valid anymore as they have been scoped to sections
    # Do we need to catch this?
  end

  private

  def create_and_assign_default_section
    StructuredMeeting.includes(:agenda_items).find_each do |meeting|
      section = MeetingSection.create!(
        meeting:,
        title: "Untitled"
      )
      meeting.agenda_items.update_all(meeting_section_id: section.id)
    end
  end
end
