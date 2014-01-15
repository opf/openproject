# This migration comes from subscribem (originally 20140107152653)
class CreateSubscribemUsers < ActiveRecord::Migration
  def change
    create_table :subscribem_users do |t|
      t.string :login
      t.string :firstname
      t.string :lastname
      t.string :mail
      t.string :password_digest

      t.timestamps
    end
  end
end
