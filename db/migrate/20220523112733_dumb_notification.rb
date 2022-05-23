class DumbNotification < ActiveRecord::Migration[7.0]
  def change
    create_table :dumb_notifications do |t|
      t.belongs_to :author, class_name: 'User'
      t.belongs_to :recipient, class_name: 'User'
      t.text :message
      t.timestamps
    end
  end
end
