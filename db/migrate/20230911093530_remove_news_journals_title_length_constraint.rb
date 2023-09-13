class RemoveNewsJournalsTitleLengthConstraint < ActiveRecord::Migration[7.0]
  def up
    change_column(:news_journals, :title, :string, limit: nil)
  end

  def down
    change_column(:news_journals, :title, :string, limit: 60)
  end
end
