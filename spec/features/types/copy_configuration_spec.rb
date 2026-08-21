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

RSpec.describe "Copying a type's form configuration from another type", :js, with_flag: { type_variants: true } do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:source) do
    create(:type, name: "Feature").tap do |source_type|
      source_type.default_variant.attribute_groups = [["Copied group", %w[assignee]]]
      source_type.default_variant.save!
    end
  end
  shared_let(:type) { create(:type, name: "Mobile app bug") }

  before { login_as(admin) }

  it "copies the configuration through the dialog and danger confirmation and reloads in place" do
    visit edit_type_form_configuration_path(type_id: type.id)

    expect(page).to have_text("Independent mode")
    expect(page).to have_no_text("Copied group")

    click_on "Copy from type"

    expect(page).to have_text("Copy configuration")
    select_autocomplete(page.find('[data-test-selector="configuration-copy-source"]'),
                        query: "Feature",
                        select_text: "Feature")
    click_on "Save and copy"

    # The picker is swapped for the danger confirmation; Confirm stays disabled
    # until the risk is acknowledged.
    expect(page).to have_text("Copy configuration?")
    expect(page).to have_button("Confirm", disabled: true)

    find_field("confirm_dangerous_action").click
    click_on "Confirm"

    expect_flash(message: I18n.t("types.edit.reuse_mode.copy.success"))

    # The surrounding turbo frame reloads in place with the copied configuration.
    expect(page).to have_text("Copied group")
    expect(type.default_variant.reload.attribute_groups.map(&:key)).to eq(["Copied group"])
  end

  it "does not copy anything when the danger confirmation is dismissed" do
    visit edit_type_form_configuration_path(type_id: type.id)

    click_on "Copy from type"
    select_autocomplete(page.find('[data-test-selector="configuration-copy-source"]'),
                        query: "Feature",
                        select_text: "Feature")
    click_on "Save and copy"

    expect(page).to have_text("Copy configuration?")
    click_on "Close"

    expect(page).to have_no_text("Copy configuration?")
    expect(page).to have_no_text("Copied group")
    expect(type.default_variant.reload.read_attribute(:attribute_groups)).to be_empty
  end
end
