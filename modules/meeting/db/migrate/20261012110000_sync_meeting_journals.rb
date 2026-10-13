# frozen_string_literal: true

class SyncMeetingJournals < ActiveRecord::Migration[8.1]
  def up
    Meetings::SyncJournalsJob.perform_later
  end

  def down; end
end
