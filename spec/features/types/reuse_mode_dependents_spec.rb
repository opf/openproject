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

RSpec.describe "The reuse mode and dependents boxes on a type's configuration tab",
               :js,
               with_flag: { type_variants: true } do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Task") }
  shared_let(:borrowing_type) { create(:type, name: "Feature") }
  shared_let(:borrowing_variant) { create(:type_variant, type: borrowing_type, variant_name: "Mobile") }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  before { login_as(admin) }

  it "shows both boxes side by side, and the reuse mode actions still work" do
    visit edit_type_form_configuration_path(type_id: type.id)

    expect(page).to have_text("Manual configuration")
    expect(page).to have_text("No dependent types")
    expect(page).to have_text("No other type or variant inherits from this configuration")

    click_on "Inherit from another type"

    expect(page).to have_text("Inherit this configuration from a source type")
    expect(page).to have_button("Switch")
  end

  it "counts the dependents and lists them in the dialog" do
    link_configuration(borrowing_type, source: type, aspect:)
    link_configuration(borrowing_variant, source: type, aspect:)

    visit edit_type_form_configuration_path(type_id: type.id)

    within_test_selector("reuse-mode-dependents") do
      expect(page).to have_text("2 dependent types")
      expect(page).to have_text("inherited by 2 other types or variants")
    end

    click_on "View dependent types"

    within_test_selector("direct-dependents-list") do
      expect(page).to have_link("Feature")
      expect(page).to have_link("Mobile")
      expect(page).to have_text("Variant of Feature")
    end

    expect(page).to have_no_test_selector("indirect-dependents-list")
  end

  it "counts a whole chain and splits the dialog into direct and indirect dependents" do
    bug_variant = create(:type_variant, type: create(:type, name: "Bug"), variant_name: "iOS")
    server_variant = create(:type_variant, type: create(:type, name: "Server"), variant_name: "Web")

    link_configuration(bug_variant, source: type, aspect:)
    link_configuration(server_variant, source: bug_variant, aspect:)

    visit edit_type_form_configuration_path(type_id: type.id)

    within_test_selector("reuse-mode-dependents") do
      expect(page).to have_text("2 dependent types")
    end

    click_on "View dependent types"

    within_test_selector("direct-dependents-list") do
      expect(page).to have_css(".Box-header", text: "Direct dependents")
      expect(page).to have_link("iOS")
      expect(page).to have_text("Variant of Bug")
    end

    within_test_selector("indirect-dependents-list") do
      expect(page).to have_css(".Box-header", text: "Dependents through other types")
      expect(page).to have_link("Web")
      expect(page).to have_text("Variant of Server, inheriting via iOS")
      expect(page).to have_link("iOS")
    end
  end

  it "navigates to a dependent's own configuration from the dialog" do
    link_configuration(borrowing_variant, source: type, aspect:)

    visit edit_type_form_configuration_path(type_id: type.id)

    click_on "View dependent types"
    click_on "Mobile"

    expect(page).to have_current_path(
      edit_type_form_configuration_path(type_id: borrowing_type.id, variant_id: borrowing_variant.id)
    )
    expect(page).to have_text("Inherited configuration")
    expect(page).to have_css(".color-bg-accent", text: "Inherited configuration")
  end
end
