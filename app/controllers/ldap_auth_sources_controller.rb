class LdapAuthSourcesController < AuthSourcesController

  protected
  
  def auth_source_class
    AuthSourceLdap
  end
end
