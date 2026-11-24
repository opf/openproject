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

RSpec.describe Admin::Settings::ColumnSelectionComponent, type: :component do
  let(:columns) do
    [
      { id: "id", name: "ID" },
      { id: "subject", name: "Subject" },
      { id: "status", name: "Status" }
    ]
  end
  let(:selected) { columns.first(2) }
  let(:protected) { columns.first(1) }
  let(:rendered) { render_inline(described_class.new(name: :default_columns, columns:, selected:, protected:)) }

  subject(:component) do
    rendered.children => [component]
    component
  end

  it "renders the draggable autocompleter Angular component" do
    expect(component.name).to eq("opce-draggable-autocompleter")
  end

  it "does not autofocus the input and sets the field name" do
    expect(JSON.parse(component["data-autofocus"])).to be(false)
    expect(JSON.parse(component["data-name"])).to eq "settings[default_columns][]"
  end

  it "passes on the available, selected and protected columns" do
    expect(JSON.parse(component["data-options"])).to eq(
      [
        { "id" => "id", "name" => "ID" },
        { "id" => "subject", "name" => "Subject" },
        { "id" => "status", "name" => "Status" }
      ]
    )
    expect(JSON.parse(component["data-selected"])).to eq(
      [
        { "id" => "id", "name" => "ID" },
        { "id" => "subject", "name" => "Subject" }
      ]
    )
    expect(JSON.parse(component["data-protected"])).to eq([{ "id" => "id", "name" => "ID" }])
  end
end
