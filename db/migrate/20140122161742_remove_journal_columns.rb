class RemoveJournalColumns < ActiveRecord::Migration
  def up

    change_table :work_package_journals do |t|
      t.remove :lock_version, :created_at, :root_id, :lft, :rgt
    end

    change_table :wiki_content_journals do |t|
      t.remove :lock_version
    end

    change_table :time_entry_journals do |t|
      t.remove :created_on
    end

    change_table :news_journals do |t|
      t.remove :created_on
    end

    change_table :message_journals do |t|
      t.remove :created_on
    end

    change_table :journals do |t|
      t.remove_references :journable_data, polymorphic: true
    end

    change_table :attachment_journals do |t|
      t.remove :created_on
    end

    change_table :customizable_journals do |t|
      t.remove   :default_value
    end

    drop_table :journal_details

  end

  def down

    change_table :work_package_journals do |t|
      t.integer  :lock_version,                    :default => 0,  :null => false
      t.datetime :created_at
      t.integer  :root_id
      t.integer  :lft
      t.integer  :rgt
    end

    change_table :wiki_content_journals do |t|
      t.integer  :lock_version,                     :default => 0,  :null => false
    end

    change_table :time_entry_journals do |t|
      t.datetime :created_on
    end

    change_table :news_journals do |t|
      t.datetime :created_on
    end

    change_table :message_journals do |t|
      t.datetime :created_on
    end

    change_table :journals do |t|
      t.references :journable_data, polymorphic: true
    end

    change_table :attachment_journals do |t|
      t.datetime :created_on
    end

    change_table :customizable_journals do |t|
      t.string   :default_value
    end

    create_table :journal_details do |t|
      t.integer  :journal_id,               :default => 0,  :null => false
      t.string   :property,   :limit => 30, :default => "", :null => false
      t.string   :prop_key,   :limit => 30, :default => "", :null => false
      t.text     :old_value
      t.text     :value
    end

  end
end
