class DummyAuthSource < AuthSource
  def test_connection
    # the dummy connection is always available
  end

  def authenticate(login, password)
    existing_user(login, password) || on_the_fly_user(login)
  end

  def auth_method_name
    'LDAP'
  end

  private

  def existing_user(login, password)
    registered_login?(login) && password == 'dummy'
  end

  def on_the_fly_user(login)
    return nil unless onthefly_register?

    {
      firstname: login.capitalize,
      lastname: 'Dummy',
      mail: 'login@DerpLAP.net',
      auth_source_id: id
    }
  end

  def registered_login?(login)
    not users.where(login: login).empty? # empty? to use EXISTS query
  end

  # Does this auth source backend allow password changes?
  def self.allow_password_changes?
    false
  end
end
