class RemoveSummaryFromProject < ActiveRecord::Migration
  def change
    remove_column :projects, :summary
  end
end
