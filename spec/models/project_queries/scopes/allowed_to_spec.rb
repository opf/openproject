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

RSpec.describe ProjectQuery, "#allowed to" do # rubocop:disable RSpec/SpecFilePathFormat
  shared_let(:user) { create(:user) }
  shared_let(:other_user) { create(:user) }

  let(:checked_user) { user }
  let(:permission) { :view_project_query }

  subject { described_class.allowed_to(checked_user, permission) }

  shared_let(:view_role) { create(:view_project_query_role) }
  shared_let(:edit_role) { create(:edit_project_query_role) }

  shared_let(:owned_query) { create(:project_query, user:) }
  shared_let(:owned_public_query) { create(:project_query, user:, public: true) }
  shared_let(:public_other_query) { create(:project_query, user: other_user, public: true) }
  shared_let(:private_other_query) { create(:project_query, user: other_user) }
  shared_let(:private_other_query_with_view) do
    create(:project_query, user: other_user, members: [
             create(:project_query_member, user:, roles: [view_role])
           ])
  end
  shared_let(:private_other_query_with_edit) do
    create(:project_query, user: other_user, members: [
             create(:project_query_member, user:, roles: [edit_role])
           ])
  end

  context "when the user is locked" do
    let(:checked_user) { create(:locked_user) }

    it { is_expected.to be_empty }
  end

  context "when no permission is checked" do
    let(:permission) { nil }

    it { is_expected.to be_empty }
  end

  context "when the user is anonymous" do
    let(:checked_user) { create(:anonymous) }

    it { is_expected.to be_empty }
  end

  context "for the view permission" do
    let(:permission) { :view_project_query }

    it do
      expect(subject).to contain_exactly(
        # public queries
        public_other_query,
        owned_public_query,
        # user owned queries
        owned_query,
        # view membership queries
        private_other_query_with_view,
        private_other_query_with_edit
      )
    end
  end

  context "for the edit permission" do
    let(:permission) { :edit_project_query }

    context "when the user can manage global queries" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_globally(:manage_public_project_queries)
        end
      end

      it do
        expect(subject).to contain_exactly(
          # public queries
          public_other_query,
          owned_public_query,
          # user owned queries
          owned_query,
          # view membership queries
          private_other_query_with_edit
        )
      end
    end

    context "when the user cannot manage global queries" do
      it do
        expect(subject).to contain_exactly(
          # user owned queries
          owned_query,
          # edit membership queries
          private_other_query_with_edit
        )
      end
    end
  end
end
