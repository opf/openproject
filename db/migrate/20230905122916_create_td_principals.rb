class CreateTdPrincipals < ActiveRecord::Migration[7.0]
  def change
    create_table :td_principals do |t|
      t.integer :ticket_id
      t.float :td_principal

      t.timestamps
    end
  end
end
