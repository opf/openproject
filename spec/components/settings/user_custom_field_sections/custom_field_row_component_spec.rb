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
  let(:other_sections) { UserCustomFieldSection.where.not(id: section.id).order(:position) }

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
      render_inline(described_class.new(user_custom_field: field, other_sections:))
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

  context "with another section to move to" do
    let!(:other_section) { create(:user_custom_field_section, name: "Other section") }

    it "renders a Move to section submenu listing the other section" do
      subject

      expect(page).to have_selector(:menuitem, "Move to section", exact: true)
      move_item = page.find(:menuitem, "Move to section", exact: true)
      expect(page).to have_selector(:menu, id: move_item["aria-controls"]) do |submenu|
        expect(submenu).to have_selector(:menuitem, other_section.name)
      end
    end

    it "submits the destination section's id with no anchor, landing the field first" do
      subject

      item = page.find(:menuitem, other_section.name)
      form = item.ancestor("form")
      expect(form[:action]).to eq(drop_admin_settings_user_custom_field_section_field_path(field.id))
      expect(form).to have_css("input[name='list_type'][value='user_field']", visible: :all)
      expect(form).to have_css("input[name='list_id'][value='#{other_section.id}']", visible: :all)
    end
  end

  context "with no other section" do
    it "renders no Move to section item" do
      subject

      expect(page).to have_no_selector(:menuitem, "Move to section")
    end
  end
end
