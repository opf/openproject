class AddFailedLoginCountLastFailedLoginOnToUser < ActiveRecord::Migration
  def change
    add_column :users, :failed_login_count, :integer, :default => 0
    add_column :users, :last_failed_login_on, :timestamp
  end
end
