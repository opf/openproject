class AddDataToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :data, :json, null: true
  end
end
