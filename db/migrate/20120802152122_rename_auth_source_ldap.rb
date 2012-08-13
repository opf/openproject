class RenameAuthSourceLdap < ActiveRecord::Migration
  def self.up
    AuthSource.update_all ["type = ?", "LdapAuthSource"], ["type = ?", "AuthSourceLdap"]
  end

  def self.down
    AuthSource.update_all ["type = ?", "AuthSourceLdap"], ["type = ?", "LdapAuthSource"]
  end
end
