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
               :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Task") }

  let(:aspect) { TypeVariant::FORM_CONFIGURATION }

  before { login_as(admin) }

  it "shows both boxes side by side, and the reuse mode actions still work" do
    variant = create(:type_variant, type:, variant_name: "Hardware")
    visit edit_type_form_configuration_path(**variant.path_args)

    expect(page).to have_text("Manual configuration")
    expect(page).to have_text("No dependent types")
    expect(page).to have_text("No other type or variant inherits from this configuration")

    click_on "Inherit from parent"

    expect(page).to have_text("Switch configuration mode?")
    expect(page).to have_button(I18n.t(:button_confirm), disabled: :all)
  end

  it "counts the dependents and lists them in the dialog" do
    link_configuration(create(:type_variant, type:, variant_name: "Mobile"), aspect:)
    link_configuration(create(:type_variant, type:, variant_name: "Desktop"), aspect:)

    visit edit_type_form_configuration_path(type_id: type.id)

    within_test_selector("reuse-mode-dependents") do
      expect(page).to have_text("2 dependent types")
      expect(page).to have_text("inherited by 2 other types or variants")
    end

    click_on "View dependent types"

    within_test_selector("dependents-list") do
      expect(page).to have_link("Mobile")
      expect(page).to have_link("Desktop")
      expect(page).to have_text("Variant of Task")
    end
  end

  it "navigates to a dependent's own configuration from the dialog" do
    dependent = create(:type_variant, type:, variant_name: "Mobile")
    link_configuration(dependent, aspect:)

    visit edit_type_form_configuration_path(type_id: type.id)

    click_on "View dependent types"
    click_on "Mobile"

    expect(page).to have_current_path(edit_type_form_configuration_path(**dependent.path_args))
    expect(page).to have_text("Inherited configuration")
    expect(page).to have_css(".color-bg-accent", text: "Inherited configuration")
  end
end
