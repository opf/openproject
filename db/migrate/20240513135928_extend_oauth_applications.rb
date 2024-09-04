class ExtendOAuthApplications < ActiveRecord::Migration[7.1]
  def change
    change_table :oauth_applications, bulk: true do |t|
      t.column :enabled, :boolean, default: true, null: false
      t.column :builtin, :boolean, default: false, null: false
    end
  end
end
