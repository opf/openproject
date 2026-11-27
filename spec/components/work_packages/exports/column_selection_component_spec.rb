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

RSpec.describe WorkPackages::Exports::ColumnSelectionComponent, type: :component do
  let(:query) { create(:query, column_names: %w[id subject type status priority start_date due_date]) }
  let(:export_settings) { query.export_settings_for("pdf_table") }

  def ids(columns)
    columns.pluck(:id)
  end

  it "preselects all view columns when no maximum is given" do
    component = described_class.new(export_settings, "columns-select", "caption")

    expect(ids(component.selected_columns)).to eq(%w[id subject type status priority start_date due_date])
  end

  it "caps the preselection at the maximum" do
    component = described_class.new(export_settings, "columns-select", "caption", max_columns: 3)

    expect(ids(component.selected_columns)).to eq(%w[id subject type])
  end

  it "renders an unlimited picker when no maximum is given" do
    render_inline(described_class.new(export_settings, "columns-select", "caption"))

    expect(page.find("opce-draggable-autocompleter", visible: :all)["data-max-items"]).to eq("null")
  end
end
