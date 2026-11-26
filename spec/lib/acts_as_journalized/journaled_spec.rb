# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Journalized Objects" do
  describe "journal_editable_by?" do
    context "when the journable is a work package" do
      let!(:user) { create(:user, member_with_permissions: { project => [] }) }
      let!(:project) { create(:project_with_types) }
      let!(:work_package) do
        create(:work_package,
               type: project.enabled_types.first,
               author: user,
               project:,
               description: "")
      end

      subject { work_package.journal_editable_by?(work_package.journals.first, user) }

      context 'and the user has no permission to "edit_work_packages"' do
        it { is_expected.to be_falsey }
      end
    end

    context "when the journable belongs to a project and the journal was written by someone else" do
      let(:project) { create(:project) }
      let(:budget) { create(:budget, project:, author: create(:user)) }
      let(:admin) { create(:admin) }

      subject { budget.journal_editable_by?(budget.journals.first, admin) }

      context "for an admin" do
        it { is_expected.to be true }
      end

      context "for an admin with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
        context "when not elevated in the project" do
          it { is_expected.to be false }
        end

        context "when elevated in the project" do
          before { admin.admin_elevation = Users::AdminElevation.in_projects([project.id]) }

          it { is_expected.to be true }
        end
      end
    end

    context "when the journable does not belong to a project" do
      let(:attachment) { create(:attachment, container: nil, author: create(:user)) }
      let(:admin) { create(:admin) }

      subject { attachment.journal_editable_by?(attachment.journals.first, admin) }

      context "for an admin with admin privilege elevation required", with_flag: { admin_privilege_elevation: true } do
        it { is_expected.to be true }
      end
    end
  end
end
