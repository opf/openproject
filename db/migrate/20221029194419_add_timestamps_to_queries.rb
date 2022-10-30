class AddTimestampsToQueries < ActiveRecord::Migration[7.0]
  def change
    add_column :queries, :timestamps, :string
  end
end
