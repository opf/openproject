class GlobalRole < Role
  unloadable
  has_many :principal_roles, :foreign_key => :role_id, :dependent => :destroy
  has_many :principals, :through => :principal_roles

  def initialize(*args)
    super
    self.assignable = false
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

  def to_s #Why is this not inherited?
    name
  end

  def assignable=(value)
    raise ArgumentError if value == true
    super
  end

  def assignable_to?(user)
    true #for now
  end
end