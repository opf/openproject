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

RSpec.describe Settings::UserCustomFieldSections::CustomFieldRowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:section) { create(:user_custom_field_section) }
  let(:field) { create(:user_custom_field, custom_field_section: section) }

  before do
    # Basic data seeding, and the user_custom_field factory's own implicit
    # section association, can both leave extra sections lying around; the
    # "Move to section" assertions below need to control the full set of
    # candidate sections themselves.
    field
    UserCustomFieldSection.where.not(id: section.id).destroy_all
  end

  subject do
    with_request_url "/admin/settings/user_custom_fields" do
      render_inline(described_class.new(user_custom_field: field))
    end
  end

  it "wires its drag handle as the sortable-lists item handle target" do
    subject

    expect(page).to have_css(".handle[data-sortable-lists--item-target='handle']")
  end

  it "renders a Move submenu wired to the item controller's move action" do
    subject

    expect(page).to have_selector(:menuitem, "Move", exact: true) do |item|
      expect(item["aria-haspopup"]).to eq("true")
    end
  end
end
