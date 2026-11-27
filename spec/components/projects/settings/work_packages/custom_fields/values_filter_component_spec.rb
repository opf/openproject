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

RSpec.describe Projects::Settings::WorkPackages::CustomFields::ValuesFilterComponent, type: :component do
  shared_let(:project) { create(:project) }

  let(:query) { Queries::WorkPackageCustomFields::WorkPackageCustomFieldQuery.new.tap { |query| query.project = project } }
  let(:base_path) { "/projects/#{project.identifier}/settings/work_packages/custom_fields" }

  it "shows all custom fields by default" do
    render_inline(described_class.new(project:, query:))

    expect(page).to have_button("Values: All")
    expect(page).to have_css("[aria-checked=true]", text: "All custom fields")
  end

  it "offers each option, keeping the other filters" do
    query.where(:field_format, "=", %w[list])

    render_inline(described_class.new(project:, query:))

    format_filter = { "field_format" => { "operator" => "=", "values" => ["list"] } }
    customized = { "project_values" => { "operator" => "customized", "values" => [] } }
    expect(page).to have_link("All custom fields", href: "#{base_path}?#{{ filters: [format_filter].to_json }.to_query}")
    expect(page).to have_link("Customized in this project",
                              href: "#{base_path}?#{{ filters: [format_filter, customized].to_json }.to_query}")
  end

  it "names the selected option" do
    query.where(:project_values, "customizable", [])

    render_inline(described_class.new(project:, query:))

    expect(page).to have_button("Values: Customizable in this project")
    expect(page).to have_css("[aria-checked=true]", text: "Customizable in this project")
  end
end
