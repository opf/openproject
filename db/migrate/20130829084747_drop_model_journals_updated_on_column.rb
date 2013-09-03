class DropModelJournalsUpdatedOnColumn < ActiveRecord::Migration
  def up
    remove_column :work_package_journals, :updated_at
    remove_column :wiki_content_journals, :updated_on
    remove_column :time_entry_journals, :updated_on
    remove_column :message_journals, :updated_on
  end

  def down
    add_column :work_package_journals, :updated_at, :datetime
    add_column :wiki_content_journals, :updated_on, :datetime
    add_column :time_entry_journals, :updated_on, :datetime
    add_column :message_journals, :updated_on, :datetime
  end
end
