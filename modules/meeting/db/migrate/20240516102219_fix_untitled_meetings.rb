class FixUntitledMeetings < ActiveRecord::Migration[7.1]
  def up
    MeetingSection.where(title: "Untitled").update_all(title: "")
  end

  def down
    MeetingSection.where(title: "").update_all(title: "Untitled")
  end
end
