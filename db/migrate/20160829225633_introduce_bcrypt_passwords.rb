class IntroduceBcryptPasswords < ActiveRecord::Migration[5.0]
  def up
    # Introduce type to UserPassword
    add_column :user_passwords, :type, :string, null: true

    # Increase hash limit due to bcrypt embedded salt
    change_column :user_passwords, :hashed_password, :string, limit: 128, null: false

    # All current passwords are assumed to be SHA-1 salted.
    UserPassword.update_all(type: 'UserPassword::SHA1')

    # Make type non-optional
    change_column :user_passwords, :type, :string, null: false

    # Make salt explicitly optional
    change_column_null :user_passwords, :salt, true
  end

  def down
    unless ENV['OPENPROJECT_CONFIRM_ROLLBACK'] == '20160829225633'
      raise ActiveRecord::IrreversibleMigration, <<-EXC.strip_heredoc
        WARNING

        You cannot roll back this migration without losing passwords.
        If you really want to do undo BCrypt passwords, set the following ENV variable:

        export OPENPROJECT_CONFIRM_ROLLBACK="20160829225633"
      EXC
    end

    UserPassword.where(type: 'UserPassword::Bcrypt').delete_all
    remove_column :user_passwords, :type
    change_column :user_passwords, :hashed_password, :string, limit: 40
    # Salt was (implictly) optional
  end
end
