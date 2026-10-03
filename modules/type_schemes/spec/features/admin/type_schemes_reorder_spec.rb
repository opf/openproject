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

RSpec.describe "Reordering types in a type scheme", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:epic) { create(:type, name: "Epic") }
  shared_let(:story) { create(:type, name: "Story") }
  shared_let(:scheme) { create(:type_scheme, name: "Dev", types: [epic, story]) }

  current_user { admin }

  it "moves a row with the arrow buttons and saves the new order" do
    visit edit_admin_type_scheme_path(scheme)

    click_button "Move Epic down"
    expect(page).to have_css("[role=status]", text: "Epic moved to position 2 of")

    click_button "Save"
    expect(page).to have_text("Successful update.")
    expect(scheme.reload.types.first(2)).to eq [story, epic]
  end

  it "moves the focused row with Alt + Arrow Down and keeps focus on the control" do
    visit edit_admin_type_scheme_path(scheme)

    checkbox = find_by_id("type_scheme_types_#{epic.id}_enabled")
    checkbox.send_keys([:alt, :down])

    expect(page).to have_css("[role=status]", text: "Epic moved to position 2 of")
    expect(page.evaluate_script("document.activeElement.id")).to eq "type_scheme_types_#{epic.id}_enabled"
  end

  it "hands the default over when the default type is unchecked" do
    visit edit_admin_type_scheme_path(scheme)

    default_item = scheme.items.find_by!(is_default: true)
    uncheck "type_scheme_types_#{default_item.type_id}_enabled"

    expect(page).to have_field("type_scheme_default_type_#{default_item.type_id}", disabled: true, checked: false)
    expect(page).to have_css("[role=status]", text: "Default type is now")
  end
end
