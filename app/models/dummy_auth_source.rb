class DummyAuthSource < AuthSource
  def test_connection
    # the dummy connection is always available
  end

  def authenticate(login, password)
    existing_user(login, password) || on_the_fly_user(login)
  end

  def find_user(login)
    find_registered_user(login) || find_on_the_fly_user(login)
  end

  def auth_method_name
    'LDAP'
  end

  private

  def find_registered_user(login)
    registered_login?(login) &&
      User
        .find_by(login: login)
        .attributes
        .slice("firstname", "lastname", "mail")
        .merge(auth_source_id: id)
  end

  def find_on_the_fly_user(login)
    dummy_login?(login) && on_the_fly_user(login)
  end

  def dummy_login?(login)
    login.start_with? "dummy_"
  end

  def existing_user(login, password)
    registered_login?(login) && password == 'dummy' && find_registered_user(login)
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
