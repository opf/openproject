class RenameEndDateOnAlternateDates < ActiveRecord::Migration
  def change
    rename_column :alternate_dates, :end_date, :due_date
  end
end
