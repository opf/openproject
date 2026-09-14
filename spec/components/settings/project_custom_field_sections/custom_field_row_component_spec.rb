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

RSpec.describe Settings::ProjectCustomFieldSections::CustomFieldRowComponent, type: :component do
  let(:field) { create(:project_custom_field) }

  it "keys its wrapper by the custom field so morphs match rows" do
    render_inline(described_class.new(project_custom_field: field, first: true, last: false))

    expect(page).to have_css(
      "##{described_class.component_id(field)}"
    )
  end

  it "wires its drag handle as the sortable-lists item handle target" do
    # The sortable-lists--item controller itself lives on the enclosing
    # BorderBox <li> rendered by ShowComponent, not on this row's own
    # wrapper div; only the handle target is asserted here.
    render_inline(described_class.new(project_custom_field: field, first: true, last: false))

    expect(page).to have_css(
      "##{described_class.component_id(field)} .handle[data-sortable-lists--item-target='handle']"
    )
  end
end
