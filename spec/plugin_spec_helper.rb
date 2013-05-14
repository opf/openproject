module Cost
  module PluginSpecHelper
    def is_member(project, user, permissions = [])
      role = ::FactoryGirl.create(:role, :permissions => permissions)

      ::FactoryGirl.create(:member, :project => project,
                                    :principal => user,
                                    :roles => [role])
      user.reload
    end
  end
end
