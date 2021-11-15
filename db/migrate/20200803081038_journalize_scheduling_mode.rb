class JournalizeSchedulingMode < ActiveRecord::Migration[6.0]
  def change
    add_column :work_package_journals, :schedule_manually, :boolean, default: false
  end
end
