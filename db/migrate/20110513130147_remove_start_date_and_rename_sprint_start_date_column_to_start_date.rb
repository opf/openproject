class RemoveStartDateAndRenameSprintStartDateColumnToStartDate < ActiveRecord::Migration
  def self.up
    unless Version.column_names.include?("start_date")
      raise "Abort! This migration depends on Chiliproject www.chiliproject.org/issues/279! Migrations
      were not executed in the correct order"
    end
    
    Version.transaction do
      Version.all.each do |version|
        unless version.start_date.nil?
          unless version.sprint_start_date.nil?
            raise ActiveRecord::Rollback, "Version has a start date and a sprint start date!
            Migrations were not executed in the correct order"
          else
            pp "Moving start date"
            version.sprint_start_date = version.start_date
            version.save!
          end
        end
      end
      remove_column :versions, :start_date
      rename_column(:versions, :sprint_start_date, :start_date)
    end
  end

  def self.down
    rename_column(:versions, :start_date, :sprint_start_date)
    add_column :versions, :start_date, :date
  end
end
