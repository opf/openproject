class AddEstimatedTimeToTdPrincipals < ActiveRecord::Migration[7.0]
  def change
    add_column :td_principals, :estimated_time, :float, default: 1
  end
end
