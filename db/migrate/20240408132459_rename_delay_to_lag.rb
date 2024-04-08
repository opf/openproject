class RenameDelayToLag < ActiveRecord::Migration[7.1]
  def change
    rename_column :relations, :delay, :lag

  end
end
