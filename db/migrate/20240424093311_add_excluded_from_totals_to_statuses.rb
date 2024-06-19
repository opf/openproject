class AddExcludedFromTotalsToStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :statuses, :excluded_from_totals, :boolean, default: false, null: false
  end
end
