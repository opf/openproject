class AddCronToDelayedJobs < ActiveRecord::Migration<%= migration_version %>
  def self.up
    add_column :delayed_jobs, :cron, :string
  end

  def self.down
    remove_column :delayed_jobs, :cron
  end
end
