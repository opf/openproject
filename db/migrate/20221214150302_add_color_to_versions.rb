class AddColorToVersions < ActiveRecord::Migration[7.0]
  def change
    add_reference :versions, :color, foreign_key: true
  end
end
