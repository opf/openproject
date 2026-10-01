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

RSpec.describe "Edit project custom fields on project overview page", :js do
  let(:project) { create(:project) }
  let(:admin) { create(:admin) }

  let(:project_custom_field_section) { create(:project_custom_field_section, name: "Section A") }
  let(:text_project_custom_field) do
    create(:text_project_custom_field,
           name: "Required Foo",
           project_custom_field_section:)
  end

  let(:overview_page) { Pages::Projects::Show.new(project) }

  before do
    create(:project_custom_field_project_mapping, project:, project_custom_field: text_project_custom_field)
    login_as admin
    overview_page.visit_page
  end

  it "opens a dialog showing the input for project custom field" do
    field = overview_page.open_modal_for_custom_field(text_project_custom_field)
    dialog = field.dialog

    dialog.expect_open

    dialog.within_async_content(close_after_yield: true) do
      expect(page).to have_content(text_project_custom_field.name)
    end
  end

  it "renders the dialog body asynchronically" do
    dialog = Components::Common::InplaceEditFields::Dialog.new(project, text_project_custom_field.attribute_name.to_sym)
    expect(page).to have_no_css(dialog.async_content_container_css_selector, visible: :all)

    field = overview_page.open_modal_for_custom_field(text_project_custom_field)
    dialog = field.dialog

    expect(page).to have_css(dialog.async_content_container_css_selector, visible: :visible)
  end

  it "can be closed via close icon or cancel button" do
    field = overview_page.open_modal_for_custom_field(text_project_custom_field)
    dialog = field.dialog

    dialog.close_via_icon

    dialog.expect_closed

    field = overview_page.open_modal_for_custom_field(text_project_custom_field)
    dialog = field.dialog

    dialog.close_via_button

    dialog.expect_closed
  end
end
