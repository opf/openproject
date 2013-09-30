class RemoveJournalColumns < ActiveRecord::Migration
  def up

    change_table :work_package_journals do |t|
      t.remove :lock_version, :updated_at, :planning_element_status_comment, :planning_element_status_id, :sti_type, :root_id, :lft, :rgt
    end

    change_table :journals do |t|
      t.remove_references :journable_data, polymorphic: true
    end

    change_table :message_journals do |t|
      t.remove :updated_on
    end

    change_table :wiki_content_journals do |t|
      t.remove :lock_version
    end

    change_table :time_entry_journals do |t|
      t.remove :updated_on
    end

  end

  def down

    change_table :work_package_journals do |t|
      t.integer  :lock_version,                    :default => 0,  :null => false
      t.datetime :updated_at
      t.text     :planning_element_status_comment
      t.integer  :planning_element_status_id
      t.string   :sti_type
      t.integer  :root_id
      t.integer  :lft
      t.integer  :rgt
    end

    change_table :journals do |t|
      t.references :journable_data, polymorphic: true
    end

    change_table :message_journals do |t|
      t.datetime :updated_on,                       :null => false
    end

    change_table :wiki_content_journals do |t|
      t.integer  :lock_version,                     :null => false
    end

    change_table :time_entry_journals do |t|
      t.datetime :updated_on,      :null => false
    end

  end
end
