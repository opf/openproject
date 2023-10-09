require 'rails_helper'

RSpec.describe Authorization::UserPermissibleService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }

  subject { described_class.new(user) }

  describe '#allowed_globally?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_globally?(permission) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context 'when asking for a permission that is defined' do
      let(:permission) { :create_user }

      context 'and the user is a regular user' do
        context 'without a role granting the permission' do
          it { is_expected.not_to be_allowed_globally(permission) }
        end

        context 'with a role granting the permission' do
          let(:global_role) { create(:global_role, permissions: [permission]) }
          let!(:member) { create(:global_member, user:, roles: [global_role]) }

          it { is_expected.to be_allowed_globally(permission) }
        end
      end

      context 'and the user is an admin' do
        let(:user) { create(:admin) }

        it { is_expected.to be_allowed_globally(permission) }
      end
    end
  end

  describe '#allowed_in_project?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_project?(permission, project) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context 'when asking for a permission that is defined' do
      let(:permission) { :view_work_packages }

      context 'and the user is not a member of any work package or project' do
        it { is_expected.not_to be_allowed_in_project(permission, project) }
      end

      context 'and the user is a member of a project' do
        let(:role) { create(:role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_project(permission, project) }

        context 'but the project is archived' do
          before { project.update(active: false) }

          it { is_expected.not_to be_allowed_in_project(permission, project) }
        end
      end

      context 'and the user is a member of a work package' do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.not_to be_allowed_in_project(permission, project) }
      end
    end
  end

  describe '#allowed_in_any_project?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_any_project?(permission) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context 'when asking for a permission that is defined' do
      let(:permission) { :view_work_packages }

      context 'and the user is not a member of any work package or project' do
        it { is_expected.not_to be_allowed_in_any_project(permission) }
      end

      context 'and the user is a member of a project' do
        let(:role) { create(:role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_any_project(permission) }
      end

      context 'and the user is a member of a work package' do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.not_to be_allowed_in_any_project(permission) }
      end
    end
  end

  describe '#allowed_in_entity?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect do
          subject.allowed_in_entity?(permission, work_package, WorkPackage)
        end.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context 'when asking for a permission that is defined' do
      let(:permission) { :view_work_packages }

      context 'and the user is not a member of the project or the work package' do
        it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
      end

      context 'and the user is a member of the project' do
        let(:role) { create(:role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }

        context 'but the project is archived' do
          before { project.update(active: false) }

          it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
        end
      end

      context 'and the user is a member of the work package' do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }

        context 'but the project is archived' do
          before { project.update(active: false) }

          it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
        end
      end

      context 'and a user is a member of the project (not granting the permission) and the work package (granting the permission)' do
        let(:permission) { :edit_work_packages }

        let(:role) { create(:role, permissions: [:view_work_packages]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        let(:wp_role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [wp_role]) }

        it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }
      end
    end
  end

  describe '#allowed_in_any_entity?' do
    context 'when asking for a permission that is not defined' do
      let(:permission) { :not_defined }

      it 'raises an error' do
        expect { subject.allowed_in_any_entity?(permission, WorkPackage) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context 'when asking for a permission that is defined' do
      let(:permission) { :view_work_packages }

      context 'and the user is not a member of any work package or project' do
        it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage) }
      end

      context 'and the user is a member of a project' do
        let(:role) { create(:role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage) }

        context 'when specifying the same project' do
          it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage, in_project: project) }
        end

        context 'when specifying a different project' do
          let(:other_project) { create(:project) }

          it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage, in_project: other_project) }
        end
      end

      context 'and the user is a member of a work package' do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage) }
      end
    end
  end
end
