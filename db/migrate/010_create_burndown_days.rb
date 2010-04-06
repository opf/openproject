class CreateBurndownDays < ActiveRecord::Migration
    def self.up
        create_table :burndown_days do |t|
            t.column :points_committed, :integer, :null => false
            t.column :points_accepted, :integer, :null => false
            t.column :points_resolved, :integer, :null => false
            t.column :remaining_hours, :float, :null => false
            t.column :version_id, :integer, :null => false
            t.timestamps
        end

        add_index :burndown_days, :version_id

        ActiveRecord::Base.connection.commit_db_transaction
        begin
            execute "select count(*) from backlog_chart_data"
            bcd = true
        rescue
            bcd = false
        end

        if bcd
            execute %{
                insert into burndown_days (version_id, points_committed, points_accepted, created_at)
                select version_id, scope, done, backlog_chart_data.created_at
                from backlogs
                join backlog_chart_data on backlogs.id = backlog_id
            }
        end
  end

  def self.down
    #pass
  end
end
