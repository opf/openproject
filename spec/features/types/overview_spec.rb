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

RSpec.describe "The overview of a work package type",
               :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:source_type) { create(:type, name: "Feature") }
  shared_let(:variant) { create(:type_variant, type:, variant_name: "Hardware") }

  before { login_as(admin) }

  it "links every setting of the type to its own tab" do
    visit type_settings_path(type_id: type.id)

    expect(page).to have_link("Details", href: edit_type_details_path(type_id: type.id))
    expect(page).to have_link("Defaults", href: edit_type_defaults_path(type_id: type.id))
    expect(page).to have_link("Variants", href: type_variants_path(type_id: type.id))
    expect(page).to have_link("Form", href: edit_type_form_configuration_path(type_id: type.id))
    expect(page).to have_link("Workflows", href: edit_type_workflow_path(type_id: type.id))
    expect(page).to have_link("Project attributes", href: edit_type_project_attributes_path(type_id: type.id))
    expect(page).to have_link("Projects", href: edit_type_projects_path(type_id: type.id))
    expect(page).to have_link("Generate PDF", href: edit_type_pdf_export_template_index_path(type_id: type.id))
  end

  it "reports how each setting is configured" do
    link_configuration(type, source: source_type, aspect: TypeVariant::WORKFLOWS)

    visit type_settings_path(type_id: type.id)

    within("#overview-details") { expect(page).to have_text("Always manual") }
    within("#overview-defaults") { expect(page).to have_text("Manually configured") }
    within("#overview-workflow") do
      expect(page).to have_text("Inheriting from Feature")
      expect(page).to have_link("Feature",
                                href: edit_type_workflow_path(type_id: source_type.id,
                                                              variant_id: source_type.default_variant.id))
    end
  end

  it "counts the dependents of a setting and lists them in a dialog" do
    link_configuration(source_type, source: type, aspect: TypeVariant::DEFAULTS)

    visit type_settings_path(type_id: type.id)

    within("#overview-workflow") { expect(page).to have_text("-") }
    within("#overview-defaults") { click_on "1 dependent type" }

    expect(page).to have_text("These types and variants inherit the configuration of this section")
    within_test_selector("direct-dependents-list") { expect(page).to have_link("Feature") }
  end

  it "drops the variants tab from a named variant" do
    visit type_settings_path(**variant.path_args)

    expect(page).to have_link("Details", href: edit_type_details_path(**variant.path_args))
    expect(page).to have_no_link("Variants")
  end

  context "when a project owns the variant" do
    shared_let(:project) { create(:project) }
    shared_let(:owned) { create(:project_owned_type_variant, type:, project:, variant_name: "Ours") }
    shared_let(:project_admin) do
      create(:user, member_with_permissions: { project => %i[manage_project_variants] })
    end

    before { login_as(project_admin) }

    it "drops the tabs administration keeps to itself" do
      visit type_settings_path(**owned.path_args)

      expect(page).to have_link("Details", href: edit_type_details_path(**owned.path_args))
      expect(page).to have_no_link("Projects")
      expect(page).to have_no_link("Variants")
    end

    it "names a source of administration's without a link the project cannot follow" do
      link_configuration(owned, source: source_type, aspect: TypeVariant::WORKFLOWS)

      visit type_settings_path(**owned.path_args)

      within("#overview-workflow") do
        expect(page).to have_text("Inheriting from Feature")
        expect(page).to have_no_link("Feature")
      end
    end
  end
end
