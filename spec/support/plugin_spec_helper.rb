module OpenProject::Reporting
  module PluginSpecHelper
    def is_member(project, user, permissions = [])
      role = FactoryGirl.create(:role, :permissions => permissions)

      FactoryGirl.create(:member, :project => project,
                              :principal => user,
                              :roles => [role])
    end
  end
end
