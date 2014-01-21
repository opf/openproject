# This migration comes from subscribem (originally 20140107145130)
class CreateSubscribemAccounts < ActiveRecord::Migration
  def change
    create_table :subscribem_accounts do |t|
      t.string :subdomain, index: true
      t.timestamps
    end
  end
end
