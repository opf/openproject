RSpec.shared_context 'user with stubbed permissions' do |project_permissions: [], work_package_permissions: [], global_permissions: [], **attributes|
  let(:user) do
    build_stubbed(:user, **attributes) do |user|
      allow(user).to receive(:allowed_to?).with(anything, Project) do |queried_permission, queried_project|
        project == queried_project && project_permissions.include?(queried_permission)
      end

      allow(user).to receive(:allowed_to?).with(anything, WorkPackage) do |queried_permission, queried_work_package|
        work_package == queried_work_package && work_package_permissions.include?(queried_permission)
      end

      allow(user).to receive(:allowed_to?).with(anything, nil) do |queried_permission, _|
        global_permissions.include?(queried_permission)
      end
    end
  end
end
