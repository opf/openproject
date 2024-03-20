class AddHealthCheckedAtToStorages < ActiveRecord::Migration[7.0]
  def up
    add_column(:storages, :health_checked_at, :datetime, null: false, default: -> { "current_timestamp" })
  end

  def down
    remove_column(:storages, :health_checked_at)
  end
end
