# frozen_string_literal: true

class AddVoteBasedAgendaSorting < ActiveRecord::Migration[8.1]
  def change
    add_column :meetings, :agenda_sorting_mode, :integer, null: false, default: 0
    add_column :meeting_agenda_items, :reactions_changed_at, :datetime

    add_check_constraint :meetings, "agenda_sorting_mode IN (0, 1)", name: "meetings_agenda_sorting_mode"
    add_check_constraint :emoji_reactions,
                         "reactable_type <> 'MeetingAgendaItem' OR reaction IN ('thumbs_up', 'thumbs_down')",
                         name: "emoji_reactions_agenda_item_votes"
    add_index :emoji_reactions, %i[user_id reactable_type reactable_id],
              unique: true,
              where: "reactable_type = 'MeetingAgendaItem'",
              name: "index_emoji_reactions_unique_agenda_item_vote"
  end
end
