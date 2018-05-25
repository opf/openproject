class AddConsentTimestampToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :consented_at, :datetime
  end
end
