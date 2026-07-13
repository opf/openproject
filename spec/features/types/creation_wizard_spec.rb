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

    # The type's group is collapsed by default, hiding its "Add sub-type" footer link.
    find("[role='button'][aria-expanded='false']", text: bug_type.name).click

    click_on I18n.t("types.index.add_subtype", name: bug_type.name)

    # Step 1 - Details: identity only, no reuse mode to choose.
    expect(page).to have_no_text(I18n.t("types.edit.configuration_link.independent.label"))
    fill_in I18n.t("types.creation_wizard.fields.variant_label"), with: "Critical"
    click_on I18n.t(:button_continue)

    subtype = bug_type.children.find_by(name: "Critical")
    expect(subtype).to be_present

    # Step 2 (Form configuration): the reuse mode selector is offered, defaulting to Independent.
    expect(page).to have_text(I18n.t("types.edit.configuration_link.independent.label"))
    expect(page).to have_text(I18n.t("types.edit.configuration_link.linked.label"))
    expect(subtype).not_to be_linked(Type::ConfigurationLink::FORM_CONFIGURATION)

    click_on I18n.t(:button_continue) # -> Workflows
    click_on I18n.t(:button_continue) # -> Automations
    click_on I18n.t(:button_continue) # -> Projects
    click_on I18n.t(:button_continue) # -> PDF generation
    click_on I18n.t("types.creation_wizard.finish")

    expect(page).to have_current_path(types_path)
    expect(subtype.reload.parent).to eq(bug_type)
  end
end
