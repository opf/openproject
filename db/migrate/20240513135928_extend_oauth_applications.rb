class ExtendOAuthApplications < ActiveRecord::Migration[7.1]
  def change
    add_column :oauth_applications, :builtin, :boolean, default: false
    add_column :oauth_applications, :enabled, :boolean, default: true
  end
end
