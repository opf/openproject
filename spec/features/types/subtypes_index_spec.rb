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

RSpec.describe "Work package sub-types index", :js, with_flag: { subtypes: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }
  shared_let(:feature_type) { create(:type, name: "Feature") }
  shared_let(:zeta_subtype) { create(:type, name: "Zeta sub-type", parent: bug_type) }
  shared_let(:alfa_subtype) { create(:type, name: "Alfa sub-type", parent: bug_type) }

  before { login_as(admin) }

  it "makes only root types draggable via a drag handle" do
    visit types_path

    expect(page).to have_text(bug_type.name)
    expect(page).to have_text(feature_type.name)

    expect(page).to have_css("[data-draggable-id='#{bug_type.id}'] .DragHandle", visible: :all)
    expect(page).to have_css("[data-draggable-id='#{feature_type.id}'] .DragHandle", visible: :all)

    subtype_row = page.find(".Box-row", text: alfa_subtype.name, visible: :all)
    expect(subtype_row).to have_no_css(".DragHandle", visible: :all)
  end

  it "offers 'Move' only on roots, while both roots and sub-types can be configured and deleted" do
    visit types_path

    within("[data-draggable-id='#{bug_type.id}'] .Box-header") do
      expect(page).to have_link(I18n.t(:button_configure), visible: :all)
      expect(page).to have_button(I18n.t(:button_move), visible: :all)
      expect(page).to have_button(I18n.t(:button_delete), visible: :all)
    end

    within(".Box-row", text: alfa_subtype.name, visible: :all) do
      expect(page).to have_link(I18n.t(:button_configure), visible: :all)
      expect(page).to have_button(I18n.t(:button_delete), visible: :all)
      expect(page).to have_no_button(I18n.t(:button_move), visible: :all)
    end
  end

  it "lists a group's sub-types alphabetically" do
    visit types_path

    expect(page).to have_link(alfa_subtype.name, visible: :all)
    expect(page).to have_link(zeta_subtype.name, visible: :all)
    expect(page.body.index(alfa_subtype.name)).to be < page.body.index(zeta_subtype.name)
  end

  it "reorders root types via drag and drop", :selenium do
    visit types_path

    expect([bug_type, feature_type].map(&:position)).to eq([1, 2])

    drag_handle = page.find("[data-draggable-id='#{feature_type.id}'] .DragHandle")
    target = page.find("[data-draggable-id='#{bug_type.id}']")

    drag_n_drop_element(from: drag_handle, to: target)

    wait_for { feature_type.reload.position }.to eq(1)
    expect(bug_type.reload.position).to eq(2)
  end
end
