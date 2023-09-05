class DropTdPrincipals < ActiveRecord::Migration[7.0]
  def change
    drop_table :td_principals
  end
end
