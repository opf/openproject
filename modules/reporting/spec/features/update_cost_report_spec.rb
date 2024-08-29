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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")
require_relative "support/pages/cost_report_page"

RSpec.describe "updating a cost report's cost type", :js do
  let(:project) { create(:project_with_types, members: { user => create(:project_role) }) }
  let(:user) do
    create(:admin)
  end

  let(:cost_type) do
    create(:cost_type, name: "Post-war", unit: "cap", unit_plural: "caps")
  end

  let!(:cost_entry) do
    create(:cost_entry, user:, project:, cost_type:)
  end

  let(:report_page) { Pages::CostReportPage.new project }

  before do
    login_as(user)
  end

  it "works" do
    report_page.visit!

    report_page.save(as: "My Query", public: true)
    report_page.wait_for_page_to_reload

    cost_query = CostQuery.find_by!(name: "My Query")
    expect(page).to have_current_path("/projects/#{project.identifier}/cost_reports/#{cost_query.id}")

    expect(page).to have_field("Labor", checked: true)

    report_page.switch_to_type cost_type.name
    expect(page).to have_field(cost_type.name, checked: true, wait: 10)

    click_on "Save"

    # Leave the just saved query.
    report_page.visit!

    # And load it again.
    click_on "My Query"

    expect(page).to have_field(cost_type.name, checked: true)
  end
end
