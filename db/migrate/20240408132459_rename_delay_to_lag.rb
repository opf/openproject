class RenameDelayToLag < ActiveRecord::Migration[7.1]
  def change
    rename_column :relations, :delay, :lag

    # TODO remove after 14.0
    add_column :relations, :delay, :virtual, type: :integer, as: "lag", stored: true
  end
end
