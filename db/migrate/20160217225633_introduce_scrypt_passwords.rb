class IntroduceScryptPasswords < ActiveRecord::Migration
  def up
    # Introduce type to UserPassword
    add_column :user_passwords, :type, :string, null: true

    # Increase hash limit due to scrypt embedded salt
    change_column :user_passwords, :hashed_password, :string, limit: 128, null: false

    # All current passwords are assumed to be SHA-1 salted.
    UserPassword.update_all(type: 'UserPassword::SHA1')

    # Make type non-optional
    change_column :user_passwords, :type, :string, null: false

    # Make salt explicitly optional
    change_column_null :user_passwords, :salt, true
  end

  def down
    UserPassword.where(type: 'UserPassword::Scrypt').destroy_all
    remove_column :user_passwords, :type
    change_column :user_passwords, :hashed_password, :string, limit: 40
    # Salt was (implictly) optional
  end
end
