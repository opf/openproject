module OpenProject::Storages::Patches::RoleSeederPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def member
      role_data = super
      role_data[:permissions] += %i[view_file_links manage_file_links]
      role_data
    end

    def reader
      role_data = super
      role_data[:permissions] += %i[view_file_links]
      role_data
    end

    def non_member
      role_data = super
      role_data[:permissions] += %i[view_file_links]
      role_data
    end

    def anonymous
      role_data = super
      role_data[:permissions] += %i[view_file_links]
      role_data
    end
  end
end
