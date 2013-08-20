class CreateNormalizedJournals < ActiveRecord::Migration
  def change
    create_table :journals do |t|
      t.references :journable, polymorphic: true
      t.references :journable_data, polymorphic: true
      t.integer  :user_id, :default => 0, :null => false
      t.text     :notes
      t.datetime :created_at, :null => false
      t.integer  :version, :default => 0, :null => false
      t.string   :activity_type
    end
  end
end
