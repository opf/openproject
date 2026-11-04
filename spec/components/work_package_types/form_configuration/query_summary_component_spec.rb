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

require "rails_helper"

RSpec.describe WorkPackageTypes::FormConfiguration::QuerySummaryComponent, type: :component do
  it "renders semantic rows and escapes saved values" do
    rows = [{ label: "Filters", values: ["Assignee is empty", "Subject contains <script>alert(1)</script>"] }]
    render_inline(described_class.new(rows:))
    expect(page).to have_element(:dl)
    expect(page).to have_element(:dt, text: "Filters")
    expect(page).to have_element(:dd, text: "Assignee is empty")
    expect(page).to have_no_element(:script)
    expect(page).to have_text("Subject contains <script>alert(1)</script>")
  end

  it "lays rows out as a definition list the component styles itself", :aggregate_failures do
    rows = [{ label: "Filters", values: ["Assignee is empty", "Status is open"] }]
    render_inline(described_class.new(rows:))

    expect(page).to have_element(:dl, class: "type-form-configuration-query-summary")
    expect(page).to have_element(:div, class: "type-form-configuration-query-summary--item", count: 1)
    expect(page).to have_element(:dt, class: "type-form-configuration-query-summary--term", text: "Filters")
    expect(page).to have_element(:dd, class: "type-form-configuration-query-summary--description", count: 2)
  end

  it "does not render without summary rows" do
    render_inline(described_class.new(rows: nil))
    expect(page).to have_no_element(:dl)
  end
end
