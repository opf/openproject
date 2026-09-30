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

RSpec.describe "Choosing a form in the type creation wizard", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }
  shared_let(:other_type) { create(:type, name: "Feature") }
  shared_let(:existing) { other_type.default_variant.form_configuration }

  before_all { existing.update!(name: "Standard form") }

  current_user { admin }

  def expect_chosen(name)
    expect(page).to have_css("[data-test-selector='form_configuration-choice-#{name}']:checked", visible: :all)
  end

  def create_type_through_wizard(name)
    visit types_path
    click_on I18n.t("activerecord.attributes.work_package.type")
    click_on I18n.t("types.creation_wizard.start.submit")
    fill_in Type.human_attribute_name(:name), with: name
    click_on I18n.t(:button_continue)

    expect(page).to have_current_path(/step=defaults/)
    Type.find_by!(name:)
  end

  it "opens the form step of a new type on the form it configures itself" do
    create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)

    expect(page).to have_current_path(/step=form_configuration/)
    expect_chosen("new")
    expect(page).to have_no_test_selector("form_configuration-selector")
  end

  it "switches a new type to an existing form and shows it as reused", :aggregate_failures do
    type = create_type_through_wizard("Incident")
    click_on I18n.t(:button_continue)

    wait_for_turbo_stream { find_test_selector("form_configuration-choice-existing").click }
    within_dialog I18n.t("form_configurations.change.title") do
      select_autocomplete(find_test_selector("change-form_configuration-select"),
                          query: "Standard",
                          results_selector: "#change-form_configuration-dialog")
      click_on I18n.t(:button_save)
    end

    expect(page).to have_current_path(/step=form_configuration/)
    expect(type.default_variant.reload.form_configuration).to eq(existing)
    expect_chosen("existing")
    expect(page).to have_test_selector("form_configuration-selector", text: "Standard form")
  end

  it "opens the form step of a new variant on its type's form" do
    variant = WorkPackageTypes::CreateVariantService.new(user: admin, type: other_type)
                                                    .call(variant_name: "Hardware").result

    visit type_variant_creation_wizard_path(type_id: other_type.id, variant_id: variant.id, step: :form_configuration)

    expect_chosen("existing")
    within_test_selector("form_configuration-selector") do
      expect(page).to have_text("Standard form")
      expect(page).to have_text(I18n.t("form_configurations.selector.same_as_type"))
    end
  end
end
