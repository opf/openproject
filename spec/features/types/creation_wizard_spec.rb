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

RSpec.describe "Sub-type creation wizard", :js, with_flag: { subtypes: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:bug_type) { create(:type, name: "Bug") }

  before { login_as(admin) }

  it "guides the admin through creating a sub-type with defaults" do
    visit types_path

    click_on I18n.t("types.index.add_subtype", name: bug_type.name)

    # Step 1 - Details
    expect(page).to have_text(I18n.t("types.creation_wizard.reuse_mode.title"))
    fill_in I18n.t("types.creation_wizard.fields.variant_label"), with: "Critical"
    click_on I18n.t(:button_continue)

    subtype = bug_type.children.find_by(name: "Critical")
    expect(subtype).to be_present

    # Step 2 (Form configuration) -> ... -> advance through the remaining steps
    click_on I18n.t(:button_continue) # -> Workflows
    click_on I18n.t(:button_continue) # -> Automations
    click_on I18n.t(:button_continue) # -> Projects
    click_on I18n.t(:button_continue) # -> PDF generation
    click_on I18n.t("types.creation_wizard.finish")

    expect(page).to have_current_path(types_path)
    expect(subtype.reload.parent).to eq(bug_type)
  end
end
