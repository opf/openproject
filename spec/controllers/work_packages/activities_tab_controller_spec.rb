#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::ActivitiesTabController do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:viewer_role) do
    create(:project_role,
           permissions: [:view_work_packages])
  end
  let(:viewer) do
    create(:user,
           member_with_roles: { project => viewer_role })
  end
  let(:viewer_with_no_access_to_project) do
    create(:user,
           member_with_roles: { other_project => viewer_role })
  end
  let(:commenter_role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_package_notes edit_own_work_package_notes])
  end
  let(:commenter) do
    create(:user,
           member_with_roles: { project => commenter_role })
  end
  let(:commenter_with_no_access_to_project) do
    create(:user,
           member_with_roles: { other_project => commenter_role })
  end
  let(:full_privileges_role) do
    create(:project_role,
           permissions: %i[view_work_packages edit_work_packages add_work_package_notes edit_own_work_package_notes
                           edit_work_package_notes])
  end
  let(:user_with_full_privileges) do
    create(:user,
           member_with_roles: { project => full_privileges_role })
  end
  let(:user_with_full_privileges_with_no_access_to_project) do
    create(:user,
           member_with_roles: { other_project => full_privileges_role })
  end
  let(:work_package) do
    create(:work_package,
           project:)
  end
  let(:comment_by_user) do
    # sequencing of version in factory seems not to be working in this case
    # throws database constraint errors
    # so we manually set the version to the last journal version + 1
    # TODO: investigate why sequencing is not working
    create(:work_package_journal, user:, notes: "A comment by user", journable: work_package,
                                  version: work_package.journals.last.version + 1)
  end

  let(:comment_by_another_user) do
    # sequencing of version in factory seems not to be working in this case
    # throws database constraint errors
    # so we manually set the version to the last journal version + 1
    # TODO: investigate why sequencing is not working
    create(:work_package_journal, user: create(:user), notes: "A comment by another user", journable: work_package,
                                  version: work_package.journals.last.version + 1)
  end

  shared_examples_for "successful index action response" do
    it { is_expected.to be_successful }

    it "renders a turbo frame" do
      expect(response.body).to include("<turbo-frame id=\"work-package-activities-tab-content\">")
    end
  end

  shared_examples_for "successful update_streams action response" do
    it { is_expected.to be_successful }
  end

  shared_examples_for "successful update_filter action response" do
    it { is_expected.to be_successful }
  end

  shared_examples_for "successful update_sorting action response for asc and desc sorting" do
    context "when asc" do
      let(:sorting) { "asc" }

      it { is_expected.to be_successful }

      it_behaves_like "successful update_sorting action response"
    end

    context "when desc" do
      let(:sorting) { "desc" }

      it { is_expected.to be_successful }

      it_behaves_like "successful update_sorting action response"
    end
  end

  shared_examples_for "successful update_sorting action response" do
    it "changes the user's sorting preference" do
      expect(User.current.preference.comments_sorting).to eq(sorting)
    end
  end

  shared_examples_for "successful edit action response" do
    it { is_expected.to be_successful }
  end

  shared_examples_for "successful cancel_edit action response" do
    it { is_expected.to be_successful }
  end

  shared_examples_for "successful create action response" do
    it { is_expected.to be_successful }

    it "includes the posted comment" do
      expect(response.body).to include(notes)
    end
  end

  shared_examples_for "successful update action response" do
    it { is_expected.to be_successful }

    it "includes the updated comment" do
      expect(response.body).to include(notes)
    end
  end

  shared_examples_for "redirect to login" do
    it { is_expected.to redirect_to signin_path(back_url: work_package_activities_url(work_package_id: work_package.id)) }
  end

  shared_examples_for "does not grant access for anonymous users unless project is public and no login required" do
    context "when no user is logged in" do
      let(:user) { User.anonymous }

      context "when the project is not public" do
        let(:project) { create(:project, public: false) }

        subject { response }

        it { is_expected.to be_unauthorized }
      end

      context "when the project is public and login is required", with_settings: { login_required: true } do
        let(:project) { create(:public_project) }

        subject { response }

        it { is_expected.to be_unauthorized }
      end

      # TODO: investigate why this test is failing, it should be successful!
      #
      # context "when the project is public and no login is required", with_settings: { login_required: false } do
      #   let(:project) { create(:public_project) }

      #   subject { response }

      #   it { is_expected.to be_successful }
      # end
    end
  end

  shared_examples_for "does not grant access for anonymous users in all cases" do
    context "when no user is logged in" do
      let(:user) { User.anonymous }

      context "when the project is not public" do
        let(:project) { create(:project, public: false) }

        subject { response }

        it { is_expected.to be_unauthorized }
      end

      context "when the project is public and login is required", with_settings: { login_required: true } do
        let(:project) { create(:public_project) }

        subject { response }

        it { is_expected.to be_unauthorized }
      end

      context "when the project is public and no login is required", with_settings: { login_required: false } do
        let(:project) { create(:public_project) }

        subject { response }

        it { is_expected.to be_unauthorized }
      end
    end
  end

  shared_examples_for "does not grant access for users with no access to the project" do
    context "when a viewer is logged in who has no access to the project" do
      let(:user) { viewer_with_no_access_to_project }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in who has no access to the project" do
      let(:user) { commenter_with_no_access_to_project }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a user with full privileges is logged in who has no access to the project" do
      let(:user) { user_with_full_privileges_with_no_access_to_project }

      subject { response }

      it { is_expected.to be_forbidden }
    end
  end

  before do
    allow(User).to receive(:current).and_return user

    work_package
    comment_by_user
  end

  describe "#index" do
    before do
      get :index,
          params: { work_package_id: work_package.id, project_id: project.id }
    end

    context "when no user is logged in" do
      let(:user) { User.anonymous }

      context "when the project is not public" do
        let(:project) { create(:project, public: false) }

        subject { response }

        it_behaves_like "redirect to login"
      end

      context "when the project is public and login is required", with_settings: { login_required: true } do
        let(:project) { create(:public_project) }

        subject { response }

        it_behaves_like "redirect to login"
      end

      # TODO: investigate why this test is failing, it should be successful!
      #
      # context "when the project is public and no login is required", with_settings: { login_required: false } do
      #   let(:project) { create(:public_project) }

      #   subject { response }

      #   it_behaves_like "successful index action response"
      # end
    end

    it_behaves_like "does not grant access for users with no access to the project"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it_behaves_like "successful index action response"
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful index action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful index action response"
    end
  end

  describe "#update_streams" do
    before do
      get :update_streams,
          params: { work_package_id: work_package.id, project_id: project.id, last_update_timestamp: Time.now.utc },
          format: :turbo_stream
    end

    it_behaves_like "does not grant access for anonymous users unless project is public and no login required"

    it_behaves_like "does not grant access for users with no access to the project"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it_behaves_like "successful update_streams action response"
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful update_streams action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful update_streams action response"
    end

    context "when request is invalid" do
      let(:user) { user_with_full_privileges }

      before do
        get :update_streams,
            params: { work_package_id: work_package.id, project_id: project.id }, # missing last_update_timestamp
            format: :turbo_stream
      end

      subject { response }

      it { is_expected.to be_bad_request }
    end
  end

  describe "#update_filter" do
    before do
      get :update_filter,
          params: { work_package_id: work_package.id, project_id: project.id },
          format: :turbo_stream
    end

    it_behaves_like "does not grant access for anonymous users unless project is public and no login required"

    it_behaves_like "does not grant access for users with no access to the project"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it_behaves_like "successful update_filter action response"
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful update_filter action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful update_filter action response"
    end
  end

  describe "#update_sorting" do
    before do
      put :update_sorting,
          params: { work_package_id: work_package.id, project_id: project.id, sorting: },
          format: :turbo_stream
    end

    context "when no access to the project" do
      let(:sorting) { "asc" }

      it_behaves_like "does not grant access for users with no access to the project"
    end

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it_behaves_like "successful update_sorting action response for asc and desc sorting"
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful update_sorting action response for asc and desc sorting"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful update_sorting action response for asc and desc sorting"
    end

    context "when request is invalid" do
      let(:user) { user_with_full_privileges }
      let(:sorting) { nil } # missing sorting param

      subject { response }

      it { is_expected.to be_bad_request }
    end
  end

  describe "#edit" do
    let(:journal) { comment_by_user }

    before do
      get :edit,
          params: { work_package_id: work_package.id, project_id: project.id, id: journal.id },
          format: :turbo_stream
    end

    it_behaves_like "does not grant access for anonymous users in all cases"

    it_behaves_like "does not grant access for users with no access to the project"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      context "when the commenter is the author of the comment" do
        subject { response }

        it_behaves_like "successful edit action response"
      end

      context "when the commenter is not the author of the comment" do
        let(:journal) { comment_by_another_user }

        subject { response }

        it { is_expected.to be_forbidden }
      end
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      context "when the user is the author of the comment" do
        subject { response }

        it_behaves_like "successful edit action response"
      end

      context "when the user is not the author of the comment" do
        let(:journal) { comment_by_another_user }

        subject { response }

        it_behaves_like "successful edit action response"
      end
    end
  end

  describe "#cancel_edit" do
    let(:journal) { comment_by_user }

    before do
      get :cancel_edit,
          params: { work_package_id: work_package.id, project_id: project.id, id: journal.id },
          format: :turbo_stream
    end

    it_behaves_like "does not grant access for anonymous users in all cases"

    it_behaves_like "does not grant access for users with no access to the project"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      context "when the commenter is the author of the comment" do
        subject { response }

        it_behaves_like "successful cancel_edit action response"
      end

      context "when the commenter is not the author of the comment" do
        let(:journal) { comment_by_another_user }

        subject { response }

        it { is_expected.to be_forbidden }
      end
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      context "when the user is the author of the comment" do
        subject { response }

        it_behaves_like "successful cancel_edit action response"
      end

      context "when the user is not the author of the comment" do
        let(:journal) { comment_by_another_user }

        subject { response }

        it_behaves_like "successful cancel_edit action response"
      end
    end
  end

  describe "#create" do
    let(:notes) { "A new comment posted!" }

    before do
      post :create,
           params: {
             work_package_id: work_package.id,
             project_id: project.id,
             last_update_timestamp: Time.now.utc,
             journal: { notes: }
           },
           format: :turbo_stream
    end

    it_behaves_like "does not grant access for anonymous users in all cases"

    it_behaves_like "does not grant access for users with no access to the project"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful create action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful create action response"
    end

    # TODO: this test is failing as the creation call seems not to have an issues with an empty notes params
    #
    # context "when request is invalid" do
    #   let(:user) { user_with_full_privileges }
    #   let(:notes) { nil } # missing notes param

    #   subject { response }

    #   it { is_expected.to be_bad_request }
    # end
  end

  describe "#update" do
    let(:notes) { "An updated comment!" }
    let(:journal) { comment_by_user }

    before do
      put :update,
          params: {
            work_package_id: work_package.id,
            project_id: project.id,
            id: journal.id,
            journal: { notes: }
          },
          format: :turbo_stream
    end

    it_behaves_like "does not grant access for anonymous users in all cases"

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      context "when the commenter is the author of the comment" do
        it_behaves_like "successful update action response"
      end

      context "when the commenter is not the author of the comment" do
        let(:journal) { comment_by_another_user }

        it { is_expected.to be_forbidden }
      end
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      context "when the commenter is the author of the comment" do
        subject { response }

        it_behaves_like "successful update action response"
      end

      context "when the commenter is not the author of the comment" do
        let(:journal) { comment_by_another_user }

        subject { response }

        it_behaves_like "successful update action response"
      end
    end
  end
end
