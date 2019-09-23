module OpenProject::Bcf::Patches::RoleSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def member
      role_attributes = super
      role_attributes[:permissions] = role_attributes[:permissions] + %i[view_linked_issues manage_bcf]

      role_attributes
    end

    def reader
      role_attributes = super
      role_attributes[:permissions] = role_attributes[:permissions] + %i[view_linked_issues]

      role_attributes
    end

    def non_member
      role_attributes = super
      role_attributes[:permissions] = role_attributes[:permissions] + %i[view_linked_issues]

      role_attributes
    end

    def anonymous
      role_attributes = super
      role_attributes[:permissions] = role_attributes[:permissions] + %i[view_linked_issues]

      role_attributes
    end
  end
end
