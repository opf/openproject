class AddColumnProjectionsToQueries < ActiveRecord::Migration[6.1]
  def change
    add_column :queries, :projections, :jsonb, default: {}
  end
end
