class AlterUserAttributesMaxLength < ActiveRecord::Migration[6.0]
  def up
    change_column :users, :firstname, :string, limit: nil
    change_column :users, :lastname, :string, limit: nil
    change_column :users, :mail, :string, limit: nil
  end

  def down
    change_column :users, :firstname, :string, limit: 30
    change_column :users, :lastname, :string, limit: 30
    change_column :users, :mail, :string, limit: 60
  end
end
