# This migration comes from subscribem (originally 20140109124415)
class CreateSubscribemMemberships < ActiveRecord::Migration
  def change
    create_table :subscribem_memberships do |t|
      t.references :account, index: true
      t.references :user, index: true

      t.timestamps
    end
  end
end
