class AddTimestampsToQuery < ActiveRecord::Migration[5.2]
  def change
    add_column :queries, :created_at, :datetime
    add_column :queries, :updated_at, :datetime

    add_index(:queries, :updated_at)
  end
end
