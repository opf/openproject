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
  let(:viewer_role) do
    create(:project_role,
           permissions: [:view_work_packages])
  end
  let(:viewer) do
    create(:user,
           member_with_roles: { project => viewer_role })
  end
  let(:commenter_role) do
    create(:project_role,
           permissions: %i[view_work_packages add_work_package_notes edit_own_work_package_notes])
  end
  let(:commenter) do
    create(:user,
           member_with_roles: { project => commenter_role })
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

  shared_examples_for "successful update_sorting action response" do
    it { is_expected.to be_successful }
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
          params: { work_package_id: work_package.id, project_id: project.id },
          format: :turbo_stream
    end

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
  end

  describe "#update_filter" do
    before do
      get :update_filter,
          params: { work_package_id: work_package.id, project_id: project.id },
          format: :turbo_stream
    end

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
      get :update_sorting,
          params: { work_package_id: work_package.id, project_id: project.id },
          format: :turbo_stream
    end

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it_behaves_like "successful update_sorting action response"
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful update_sorting action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful update_sorting action response"
    end
  end

  describe "#edit" do
    before do
      get :edit,
          params: { work_package_id: work_package.id, project_id: project.id, id: comment_by_user.id },
          format: :turbo_stream
    end

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful edit action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful edit action response"
    end
  end

  describe "#cancel_edit" do
    before do
      get :cancel_edit,
          params: { work_package_id: work_package.id, project_id: project.id, id: comment_by_user.id },
          format: :turbo_stream
    end

    context "when a viewer is logged in" do
      let(:user) { viewer }

      subject { response }

      it { is_expected.to be_forbidden }
    end

    context "when a commenter is logged in" do
      let(:user) { commenter }

      subject { response }

      it_behaves_like "successful cancel_edit action response"
    end

    context "when a user with full privileges is logged in" do
      let(:user) { user_with_full_privileges }

      subject { response }

      it_behaves_like "successful cancel_edit action response"
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

      subject { response }

      it_behaves_like "successful update action response"
    end
  end
end
