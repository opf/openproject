class RemoveDefaultFromQueryName < ActiveRecord::Migration[7.0]
  def change
    change_column_default :queries, :name, to: nil, from: ""
  end
end
