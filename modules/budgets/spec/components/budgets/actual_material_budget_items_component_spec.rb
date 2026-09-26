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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
#
require "rails_helper"

RSpec.describe Budgets::ActualMaterialBudgetItemsComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) do
    create(
      :project,
      enabled_module_names: %i[costs work_package_tracking budgets],
      members: {
        user => member_role
      }
    )
  end

  let(:member_role) { create(:project_role, name: "Member", permissions: [:view_cost_entries]) }
  let(:budget) { create :budget, project: }
  let(:work_package) { create :work_package, project:, budget:, author: user }
  let(:user) { create :user }
  let(:cost_type) { create(:cost_type, name: "Development") }

  subject do
    described_class.new budget:, project:
  end

  before do
    login_as user
  end

  describe "with cost entries" do
    let!(:cost_entry) do
      create(:cost_entry, entity: work_package, project:, user:, cost_type:, units: 3)
    end

    it "renders the cost entry grouped by its work package" do
      rendered = render_inline(subject)

      expect(rendered).to have_css(
        "td.subject a[href='#{work_package_path(work_package)}']"
      )
      expect(rendered).to have_text(work_package.subject)
      expect(rendered).to have_text("Development")
    end
  end
end
