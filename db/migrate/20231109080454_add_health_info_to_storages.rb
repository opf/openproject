class AddHealthInfoToStorages < ActiveRecord::Migration[7.0]
  def change
    add_column :storages, :health_info, :jsonb, default: {}
  end
end
