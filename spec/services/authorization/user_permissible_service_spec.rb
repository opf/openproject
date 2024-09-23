require "rails_helper"

RSpec.describe Authorization::UserPermissibleService do
  shared_let(:user) { create(:user) }
  shared_let(:admin) { create(:admin) }
  shared_let(:anonymous_user) { create(:anonymous) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }
  shared_let(:project_query) { create(:project_query) }
  shared_let(:non_member_role) { create(:non_member, permissions: [:view_news]) }
  shared_let(:anonymous_role) { create(:anonymous_role, permissions: [:view_meetings]) }

  let(:queried_user) { user }

  subject(:service) { described_class.new(queried_user) }

  # The specs in this file do not cover all the various cases yet. Thus,
  # we rely on the Authorization.roles scope and the Project/WorkPackage.allowed_to scopes
  # to be called which is speced precisely.
  shared_examples_for "the Authorization.roles scope used" do
    before do
      allow(Authorization)
        .to receive(:roles)
              .and_call_original
    end

    it "calls the Authorization.roles scope once (cached for the second request)" do
      subject
      subject

      expect(Authorization)
        .to have_received(:roles)
              .once
              .with(queried_user, context)
    end
  end

  shared_examples_for "the Project.allowed_to scope used" do
    before do
      allow(Project)
        .to receive(:allowed_to)
              .and_call_original
    end

    it "calls the Project.allowed_to scope" do
      subject

      expect(Project)
        .to have_received(:allowed_to) do |user, perm|
        expect(user).to eq(queried_user)
        expect(perm).to be_a(OpenProject::AccessControl::Permission)
        expect(perm.name).to eq permission
      end
    end
  end

  shared_examples_for "the WorkPackage.allowed_to scope used" do
    before do
      allow(WorkPackage)
        .to receive(:allowed_to)
              .and_call_original
    end

    it "calls the WorkPackage.allowed_to scope" do
      subject

      expect(WorkPackage)
        .to have_received(:allowed_to) do |user, perm|
        expect(user).to eq(queried_user)
        expect(perm[0]).to be_a(OpenProject::AccessControl::Permission)
        expect(perm[0].name).to eq permission
      end
    end
  end

  describe "#allowed_globally?" do
    context "when asking for a permission that is not defined" do
      let(:permission) { :not_defined }

      it "raises an error" do
        expect { subject.allowed_globally?(permission) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context "when asking for a permission that is defined" do
      let(:permission) { :create_user }

      context "and the user is a regular user" do
        context "without a role granting the permission" do
          it { is_expected.not_to be_allowed_globally(permission) }
        end

        context "with a role granting the permission" do
          let(:global_role) { create(:global_role, permissions: [permission]) }
          let!(:member) { create(:global_member, user:, roles: [global_role]) }

          it { is_expected.to be_allowed_globally(permission) }

          context "and the account is locked" do
            before { user.locked! }

            it { is_expected.not_to be_allowed_globally(permission) }
          end
        end
      end

      context "and the user is an admin" do
        let(:user) { create(:admin) }

        it { is_expected.to be_allowed_globally(permission) }

        context "and the account is locked" do
          before { user.locked! }

          it { is_expected.not_to be_allowed_globally(permission) }
        end
      end

      it_behaves_like "the Authorization.roles scope used" do
        let(:context) { nil }
        subject { service.allowed_globally?(permission) }
      end
    end
  end

  describe "#allowed_in_project?" do
    context "when asking for a permission that is not defined" do
      let(:permission) { :not_defined }

      it "raises an error" do
        expect { subject.allowed_in_project?(permission, project) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context "when asking for a permission that is defined" do
      let(:permission) { :view_work_packages }

      it_behaves_like "the Authorization.roles scope used" do
        let(:context) { project }
        subject { service.allowed_in_project?(permission, project) }
      end

      context "and the user is not a member of any work package or project" do
        it { is_expected.not_to be_allowed_in_project(permission, project) }

        context "and the project is public" do
          before { project.update(public: true) }

          context "when requesting a permission that is not granted to the non-member role" do
            it { is_expected.not_to be_allowed_in_project(permission, project) }
          end

          context "when requesting a permission that is granted to the non-member role" do
            let(:permission) { :view_news }

            it { is_expected.to be_allowed_in_project(permission, project) }
          end

          context "when an anonymous user is requesting a permission that is granted to the anonymous role" do
            let(:queried_user) { anonymous_user }
            let(:permission) { :view_meetings }

            it { is_expected.to be_allowed_in_project(permission, project) }
          end
        end

        context "and the user is admin" do
          let(:queried_user) { admin }

          it { is_expected.to be_allowed_in_project(permission, project) }

          context "and the account is locked" do
            before { admin.locked! }

            it { is_expected.not_to be_allowed_in_project(permission, project) }
          end

          context "and the module the permission belongs to is disabled" do
            before do
              project.enabled_module_names = project.enabled_module_names - ["work_package_tracking"]
              project.reload
            end

            it { is_expected.not_to be_allowed_in_project(permission, project) }
          end
        end
      end

      context "and the user is a member of a project" do
        let(:role) { create(:project_role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_project(permission, project) }

        context "with the project being archived" do
          before { project.update(active: false) }

          it { is_expected.not_to be_allowed_in_project(permission, project) }
        end
      end

      context "and the user is a member of a work package" do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.not_to be_allowed_in_project(permission, project) }
      end
    end
  end

  describe "#allowed_in_any_project?" do
    context "when asking for a permission that is not defined" do
      let(:permission) { :not_defined }

      it "raises an error" do
        expect { subject.allowed_in_any_project?(permission) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context "when asking for a permission that is defined" do
      let(:permission) { :view_work_packages }

      context "and the user is not a member of any work package or project" do
        it { is_expected.not_to be_allowed_in_any_project(permission) }

        context "and the project is public" do
          before { project.update_column(:public, true) }

          context "and a permission is requested that is not granted to the non-member role" do
            it { is_expected.not_to be_allowed_in_any_project(permission) }
          end

          context "and a permission is requested that is granted to the non-member role" do
            let(:permission) { :view_news }

            it { is_expected.to be_allowed_in_any_project(permission) }
          end

          context "and the user is the anonymous user" do
            let(:queried_user) { anonymous_user }
            let(:permission) { :view_meetings }

            it { is_expected.to be_allowed_in_any_project(permission) }
          end

          context "and the project is archived" do
            before { project.update_column(:active, false) }

            it { is_expected.not_to be_allowed_in_any_project(permission) }
          end
        end

        context "and the user is admin" do
          let(:queried_user) { admin }

          it { is_expected.to be_allowed_in_any_project(permission) }

          context "and the account is locked" do
            before { admin.locked! }

            it { is_expected.not_to be_allowed_in_any_project(permission) }
          end

          context "and the module the permission belongs to is disabled" do
            before do
              project.enabled_module_names = project.enabled_module_names - ["work_package_tracking"]
              project.reload
            end

            it { is_expected.not_to be_allowed_in_any_project(permission) }
          end
        end
      end

      context "and the user is a member of a project" do
        let(:role) { create(:project_role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_any_project(permission) }

        context "and the project is archived" do
          before { project.update_column(:active, false) }

          it { is_expected.not_to be_allowed_in_any_project(permission) }
        end
      end

      context "and the user is a member of a work package" do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.not_to be_allowed_in_any_project(permission) }

        context "and the project is public" do
          before { project.update_column(:public, true) }

          context "and a permission is requested that is not granted to the non-member role" do
            it { is_expected.not_to be_allowed_in_any_project(permission) }
          end

          context "and a permission is requested that is granted to the non-member role" do
            let(:permission) { :view_news }

            it { is_expected.to be_allowed_in_any_project(permission) }
          end

          context "and the project is archived" do
            before { project.update_column(:active, false) }

            it { is_expected.not_to be_allowed_in_any_project(permission) }
          end
        end
      end

      it_behaves_like "the Project.allowed_to scope used" do
        subject { service.allowed_in_any_project?(permission) }
      end
    end
  end

  describe "#allowed_in_entity?" do
    context "when asking for a permission that is not defined" do
      let(:permission) { :not_defined }

      it "raises an error" do
        expect do
          subject.allowed_in_entity?(permission, work_package, WorkPackage)
        end.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context "with an entity that is not project scoped" do
      let(:permission) { :view_project_query }

      context "and the user is not a member of the entity" do
        it { is_expected.not_to be_allowed_in_entity(permission, project_query, ProjectQuery) }
      end

      context "and the user is an admin (with a permission granted to admin)" do
        let(:queried_user) { admin }

        it { is_expected.to be_allowed_in_entity(permission, project_query, ProjectQuery) }
      end

      context "and the user is member of the project query" do
        let(:role) { create(:project_query_role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project: nil, entity: project_query, roles: [role]) }

        it { is_expected.to be_allowed_in_entity(permission, project_query, ProjectQuery) }
      end
    end

    context "with an entity that is project scoped" do
      context "when asking for a permission that is defined" do
        let(:permission) { :view_work_packages }

        context "and the user is not a member of the project or the work package" do
          it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
        end

        context "and the user is admin" do
          let(:queried_user) { admin }

          it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }

          context "and the account is locked" do
            before { admin.locked! }

            it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
          end

          context "and the module the permission belongs to is disabled" do
            before do
              project.enabled_module_names = project.enabled_module_names - ["work_package_tracking"]
              project.reload
            end

            it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
          end
        end

        context "and the user is a member of the project" do
          let(:role) { create(:project_role, permissions: [permission]) }
          let!(:project_member) { create(:member, user:, project:, roles: [role]) }

          it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }

          context "with the project being archived" do
            before { project.update(active: false) }

            it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
          end

          context "without the module enabled in the project" do
            before do
              project.enabled_module_names = project.enabled_module_names - ["work_package_tracking"]
              project.reload
            end

            it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
          end

          it_behaves_like "the Authorization.roles scope used" do
            let(:context) { project }
            subject { service.allowed_in_entity?(permission, work_package, WorkPackage) }
          end
        end

        context "and the user is a member of the work package" do
          let(:role) { create(:work_package_role, permissions: [permission]) }
          let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

          it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }

          context "with the project being archived" do
            before { project.update(active: false) }

            it { is_expected.not_to be_allowed_in_entity(permission, work_package, WorkPackage) }
          end

          it_behaves_like "the Authorization.roles scope used" do
            let(:context) { work_package }
            subject { service.allowed_in_entity?(permission, work_package, WorkPackage) }
          end
        end

        context "and user is member in the project (not granting the permission) and the work package " \
                "(granting the permission)" do
          let(:permission) { :edit_work_packages }

          let(:role) { create(:project_role, permissions: [:view_work_packages]) }
          let!(:project_member) { create(:member, user:, project:, roles: [role]) }

          let(:wp_role) { create(:work_package_role, permissions: [permission]) }
          let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [wp_role]) }

          it { is_expected.to be_allowed_in_entity(permission, work_package, WorkPackage) }

          it_behaves_like "the Authorization.roles scope used" do
            let(:context) { work_package }
            subject { service.allowed_in_entity?(permission, work_package, WorkPackage) }
          end
        end
      end
    end
  end

  describe "#allowed_in_any_entity?" do
    context "when asking for a permission that is not defined" do
      let(:permission) { :not_defined }

      it "raises an error" do
        expect { subject.allowed_in_any_entity?(permission, WorkPackage) }.to raise_error(Authorization::UnknownPermissionError)
      end
    end

    context "when asking for a permission that is defined" do
      let(:permission) { :view_work_packages }

      context "and the user is not a member of any work package or project" do
        it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage) }
      end

      context "and the user is admin" do
        let(:queried_user) { admin }

        it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage) }
        it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage, in_project: project) }

        context "and the account is locked" do
          before { admin.locked! }

          it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage) }
          it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage, in_project: project) }
        end

        context "and the module the permission belongs to is disabled" do
          before do
            project.enabled_module_names = project.enabled_module_names - ["work_package_tracking"]
            project.reload
          end

          it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage) }
          it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage, in_project: project) }
        end
      end

      context "and the user is a member of a project" do
        let(:role) { create(:project_role, permissions: [permission]) }
        let!(:project_member) { create(:member, user:, project:, roles: [role]) }

        it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage) }

        context "when specifying the same project" do
          it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage, in_project: project) }
        end

        context "when specifying a different project" do
          let(:other_project) { create(:project) }

          it { is_expected.not_to be_allowed_in_any_entity(permission, WorkPackage, in_project: other_project) }
        end
      end

      context "and the user is a member of a work package" do
        let(:role) { create(:work_package_role, permissions: [permission]) }
        let!(:wp_member) { create(:work_package_member, user:, project:, entity: work_package, roles: [role]) }

        it { is_expected.to be_allowed_in_any_entity(permission, WorkPackage) }
      end

      it_behaves_like "the WorkPackage.allowed_to scope used" do
        subject { service.allowed_in_any_entity?(permission, WorkPackage) }
      end

      it_behaves_like "the WorkPackage.allowed_to scope used" do
        subject { service.allowed_in_any_entity?(permission, WorkPackage, in_project: project) }
      end
    end
  end
end
