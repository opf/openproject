# frozen_string_literal: true

# -- copyright
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

require "rails_helper"

RSpec.describe WorkPackages::Exports::PDF::Report::ExportSettingsComponent, type: :component do
  subject(:component) { described_class.new(query) }

  let(:query) { create(:query) }
  let!(:first_field) { create(:work_package_custom_field, field_format: "text", name: "First long text") }
  let!(:second_field) { create(:work_package_custom_field, field_format: "text", name: "Second long text") }

  it "selects the description and every long-text custom field by default" do
    expect(component.selected_long_text_fields).to contain_exactly(
      { id: "description", name: WorkPackage.human_attribute_name("description") },
      { id: first_field.id, name: first_field.name },
      { id: second_field.id, name: second_field.name }
    )
  end
end
