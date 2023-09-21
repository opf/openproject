require 'spec_helper'

RSpec.describe MockedPermissionHelper do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:work_package_in_project) { create(:work_package, project:) }
  let(:other_work_package) { create(:work_package) }

  context 'when not mocking any permissions' do
    before do
      mock_permissions_for(user)
    end

    it 'does not allow anything' do
      expect(user).not_to be_allowed_globally(:create_project)
      expect(user).not_to be_allowed_in_project(:create_work_packages, project)
      expect(user).not_to be_allowed_in_any_project(:create_work_packages)
      expect(user).not_to be_allowed_in_work_package(:create_work_packages, work_package_in_project)
      expect(user).not_to be_allowed_in_any_work_package(:create_work_packages)
    end
  end

  context 'when mocking a global permission' do
    prepend_before do
      puts "Running a mock"
      mock_permissions_for(user) do |mock|
        mock.globally :create_project
      end
    end

    it 'allows the global permission' do
      expect(user).to be_allowed_globally(:create_project)
    end
  end
end
