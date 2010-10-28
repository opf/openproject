class GlobalRole < Role
  has_many :principal_roles, :foreign_key => :role_id, :dependent => :destroy
  has_many :principals, :through => :principal_roles

  def allowed_to?(action)
     has_permission?(action)
  end

  def permissions=(perms) #Why is this not inherited?
    perms = perms.collect {|p| p.to_sym unless p.blank? }.compact.uniq if perms
    write_attribute(:permissions, perms)
  end

  def setable_permissions #because it is defined in the parent class
    Redmine::AccessControl.global_permissions
  end

  def self.setable_permissions
    Redmine::AccessControl.global_permissions
  end
end