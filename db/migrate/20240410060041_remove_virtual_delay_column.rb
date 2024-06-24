class RemoveVirtualDelayColumn < ActiveRecord::Migration[7.1]
  def change
    remove_column :relations, :delay, :virtual, type: :integer, as: "lag", stored: true
  end
end
