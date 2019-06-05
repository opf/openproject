class AddTimelineLabelsToQuery < ActiveRecord::Migration[5.0]
  def change
    add_column :queries, :timeline_labels, :text
  end
end
