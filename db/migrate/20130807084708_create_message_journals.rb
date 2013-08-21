class CreateMessageJournals < ActiveRecord::Migration
  def change
    create_table :message_journals do |t|
      t.integer  :journal_id,                       :null => false
      t.integer  :board_id,                         :null => false
      t.integer  :parent_id
      t.string   :subject,       :default => "",    :null => false
      t.text     :content
      t.integer  :author_id
      t.integer  :replies_count, :default => 0,     :null => false
      t.integer  :last_reply_id
      t.datetime :created_on,                       :null => false
      t.datetime :updated_on,                       :null => false
      t.boolean  :locked,        :default => false
      t.integer  :sticky,        :default => 0
    end
  end
end
