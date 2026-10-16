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
require "support/edit_fields/edit_field"
require "support/edit_fields/text_editor_field"

RSpec.describe "Inline edit activation by double click", :js do
  let(:project) { create(:project_with_types) }
  let(:work_package) { create(:work_package, project:, subject: "Some subject", description: "") }
  let(:user) do
    create(:admin, preferences: { require_double_click_for_inline_edit: true })
  end
  let(:work_packages_page) { Pages::PrimerizedSplitWorkPackage.new(work_package, project) }
  let(:field) { work_packages_page.edit_field(:subject) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it "keeps the field closed on a single click and opens it on a double click" do
    field.display_trigger_element.click
    field.expect_inactive!

    field.display_trigger_element.double_click
    field.expect_active!
    expect(field.input_element.value).to eq "Some subject"
  end

  it "asks for a double click in the empty description placeholder" do
    TextEditorField
      .new(work_packages_page, "description")
      .expect_state_text("Description: Double click to edit...")
  end
end
