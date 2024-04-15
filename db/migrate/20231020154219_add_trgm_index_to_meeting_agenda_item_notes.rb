class AddTrgmIndexToMeetingAgendaItemNotes < ActiveRecord::Migration[7.0]
  def change
    # A previous migration 20230328154645_add_gin_trgm_index_on_journals_and_custom_values
    # already enabled on the extension. Hence we do not attempt to enable it here, just
    # to use it if it's available.

    if extensions.include?("pg_trgm")
      add_index(:meeting_agenda_items, :notes, using: "gin", opclass: :gin_trgm_ops)
    end
  end
end
