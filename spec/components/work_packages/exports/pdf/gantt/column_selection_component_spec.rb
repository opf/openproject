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

RSpec.describe WorkPackages::Exports::PDF::Gantt::ColumnSelectionComponent, type: :component do
  subject(:component) { described_class.new(export_settings) }

  let(:query) { create(:query, column_names: %w[status priority subject]) }
  let(:export_settings) { query.export_settings_for("pdf_gantt") }

  def ids(columns)
    columns.pluck(:id)
  end

  it "preselects ID, subject, start date and finish date instead of the view's columns" do
    expect(ids(component.selected_columns)).to eq(%w[id subject start_date due_date])
  end

  context "with saved columns" do
    before do
      export_settings.settings = { columns: %w[due_date subject type status priority start_date id] }
    end

    it "restores them in the saved order, capped at the maximum" do
      expect(ids(component.selected_columns)).to eq(%w[due_date subject type status priority])
    end
  end

  context "with an empty saved selection" do
    before do
      export_settings.settings = { columns: [""] }
    end

    it "preselects nothing" do
      expect(component.selected_columns).to be_empty
    end
  end

  it "does not offer relation columns" do
    expect(ids(component.available_columns)).not_to include(a_string_starting_with("relations_"))
    expect(ids(component.available_columns)).to include("subject", "start_date")
  end

  it "renders an optional picker limited to the maximum column count" do
    render_inline(component)

    picker = page.find("opce-draggable-autocompleter", visible: :all)

    expect(picker["data-max-items"]).to eq("5")
    expect(picker["data-required"]).to eq("false")
    expect(picker["data-name"]).to eq('"columns"')
  end
end
