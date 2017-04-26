class SetEmptyColumnsToNull < ActiveRecord::Migration[5.0]
  def up
    Query.where("column_names = ''").update_all(column_names: nil)
  end
end
