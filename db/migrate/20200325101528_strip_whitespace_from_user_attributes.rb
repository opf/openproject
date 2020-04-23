class StripWhitespaceFromUserAttributes < ActiveRecord::Migration[6.0]
  def up
    User.update_all('login = TRIM(login), mail = TRIM(mail)')
  end

  def down
    warn <<~WARNING
      We cannot restore leading and trailing white space in user login and mail attributes.
      Please ensure you do not have logins with only leading or trailing white space differences.
    WARNING
  end
end
