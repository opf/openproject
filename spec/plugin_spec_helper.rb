module Cost
  module PluginSpecHelper
    def is_member(project, user, permissions = [])
      role = Factory.create(:role, :permissions => permissions)

      Factory.create(:member, :project => project,
                              :principal => user,
                              :roles => [role])
    end
  end
end
