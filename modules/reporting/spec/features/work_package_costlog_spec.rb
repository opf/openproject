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

require "spec_helper"

RSpec.describe "Cost report showing my own times", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  let(:user) do
    create(:user, member_with_roles: { project => role })
  end
  let(:role) { create(:project_role, permissions:) }
  let(:permissions) { %i[view_work_packages view_own_cost_entries] }

  let(:budget) do
    create(:budget, project:)
  end
  let(:cost_type) { create(:cost_type, name: "Foobar", unit: "Foobar", unit_plural: "Foobars") }
  let(:work_package) { create(:work_package, project:, budget:) }
  let(:wp_page) { Pages::FullWorkPackage.new work_package, project }

  let(:cost_entry) do
    build(:cost_entry,
          cost_type:,
          project:,
          entity: work_package,
          spent_on: Date.current,
          units: "10",
          user:,
          comments: "foobar")
  end

  before do
    login_as user
    cost_entry.save!
    wp_page.visit!
  end

  shared_examples "redirects to cost reports with the work package filter pre-populated" do
    it "allows visiting the costs which redirects to cost reports" do
      new_window = window_opened_by do
        page.find(".costsByType a", text: "10 Foobar").click
      end

      within_window new_window do
        expect(page).to have_css("#query_saved_name", text: "New cost report")
        wp_autocompleter = find("opce-autocompleter#work_package_id_select_1")
        expect_current_autocompleter_value(wp_autocompleter, expected_autocompleter_label)
        expect(page).to have_css("td.units", text: "10.0 Foobars")
      end
    end
  end

  context "in classic mode",
          with_settings: { work_packages_identifier: "classic" } do
    let(:project) { create(:project) }
    let(:expected_autocompleter_label) { "##{work_package.id} #{work_package.subject}" }

    include_examples "redirects to cost reports with the work package filter pre-populated"
  end

  context "in semantic mode",
          with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "MYPROJ") }
    let(:expected_autocompleter_label) { "MYPROJ-1 #{work_package.subject}" }

    include_examples "redirects to cost reports with the work package filter pre-populated"
  end
end
