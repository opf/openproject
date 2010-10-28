class GlobalRole < Role
  has_many :principal_global_roles, :dependent => :destroy
  has_many :principals, :through => :principal_global_roles

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_length_of :name, :maximum => 30

  acts_as_list

  serialize :permissions, Array

  def permissions
    read_attribute(:permissions) || []
  end

  def permissions=(perms)
    perms = perms.collect{|x| x.to_sym unless x.blank?}.compact.uniq if perms
    write_attribute(:permissions, perms)
  end

  def has_permission?(perm)
    permissions.include?(perm.to_sym)
  end

  def allowed_to?(action)
    has_permission?(action)
  end

  def setable_permissions
    Redmine::AccessControl.global_permissions
  end

  def to_s
    name
  end
end