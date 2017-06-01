class RemoveSummaryFromProject < ActiveRecord::Migration[4.2]
  def change
    remove_column :projects, :summary
  end
end
