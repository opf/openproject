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
#
require "rails_helper"

RSpec.describe Budgets::ActualLaborBudgetItemsComponent, type: :component do
  let(:project) do
    create(
      :project,
      enabled_module_names: %i[costs work_package_tracking budgets],
      members: {
        user => member_role
      }
    )
  end

  let(:member_role) { create(:project_role, name: "Member", permissions: [:view_time_entries]) }
  let(:budget) { create :budget, project: }
  let(:work_package) { create :work_package, project:, budget:, author: user }
  let(:user) { create :user }

  subject do
    described_class.new budget:, project:
  end

  before do
    login_as user
  end

  describe "with time entries" do
    let!(:time_entry) { create :time_entry, work_package:, user: }

    it "renders the link to the time entry's user's avatar" do
      rendered = render_inline(subject)

      expect(rendered).to have_css("opce-principal[data-title='\"#{user.name}\"']")
    end
  end
end
