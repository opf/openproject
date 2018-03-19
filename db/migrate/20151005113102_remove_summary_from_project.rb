class RemoveSummaryFromProject < ActiveRecord::Migration[5.1]
  def change
    remove_column :projects, :summary
  end
end
