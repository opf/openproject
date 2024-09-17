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

RSpec.describe WorkPackages::BulkController do
  let(:project) { create(:project_with_types) }
  let(:controller_role) { build(:project_role, permissions: %i[view_work_packages edit_work_packages]) }
  let(:user) { create(:user, member_with_roles: { project => controller_role }) }
  let(:budget) { create(:budget, project:) }
  let(:work_package) { create(:work_package, project:) }

  before do
    allow(User).to receive(:current).and_return user
  end

  describe "#update" do
    context "when a cost report is assigned" do
      before do
        put :update, params: { ids: [work_package.id],
                               work_package: { budget_id: budget.id } }
      end

      subject { work_package.reload.budget.try :id }

      it { is_expected.to eq(budget.id) }
    end
  end
end
