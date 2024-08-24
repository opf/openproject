class SetAuthorAsPresenter < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE meeting_agenda_items SET presenter_id = author_id WHERE presenter_id IS NULL"
  end

  def down
    # Nothing to do
  end
end
