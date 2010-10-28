class GlobalRole < Role
  has_many :principal_roles, :foreign_key => :role_id, :dependent => :destroy
  has_many :principals, :through => :principal_roles

  def allowed_to?(action)
     has_permission?(action)
  end

  def setable_permissions
    Redmine::AccessControl.global_permissions
  end

  #undef_method :members
  #remove_method :member_roles
end