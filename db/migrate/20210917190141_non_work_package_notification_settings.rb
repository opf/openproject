class NonWorkPackageNotificationSettings < ActiveRecord::Migration[6.1]
  def change
    change_table :notification_settings, bulk: true do |t|
      t.boolean :news_added, default: false, index: true
      t.boolean :news_commented, default: false, index: true
      t.boolean :document_added, default: false, index: true
      t.boolean :forum_messages, default: false, index: true
      t.boolean :wiki_page_added, default: false, index: true
      t.boolean :wiki_page_updated, default: false, index: true
      t.boolean :membership_added, default: false, index: true
      t.boolean :membership_updated, default: false, index: true
    end
  end
end
