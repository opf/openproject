class RemoveSomeStringLengthConstraints < ActiveRecord::Migration[7.0]
  def up
    change_column(:categories, :name, :string, limit: nil)
    change_column(:enumerations, :name, :string, limit: nil)
    change_column(:news, :title, :string, limit: nil)
    change_column(:roles, :name, :string, limit: nil)
    change_column(:statuses, :name, :string, limit: nil)
  end

  def down
    change_column(:categories, :name, :string, limit: 256)
    change_column(:enumerations, :name, :string, limit: 30)
    change_column(:news, :title, :string, limit: 60)
    change_column(:roles, :name, :string, limit: 30)
    change_column(:statuses, :name, :string, limit: 30)
  end
end
