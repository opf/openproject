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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Comparing the variants of a work package type", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, name: "Seeded project") }

  shared_let(:role) { create(:project_role) }
  shared_let(:new_status) { create(:status, name: "New") }
  shared_let(:closed_status) { create(:status, name: "Closed") }
  shared_let(:rejected_status) { create(:status, name: "Rejected") }

  shared_let(:severity) { create(:work_package_custom_field, name: "Severity") }
  shared_let(:device) { create(:work_package_custom_field, name: "Device") }

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:plain_type) { create(:type, name: "Feature") }

  shared_let(:base) do
    type.default_variant.tap do |variant|
      variant.attribute_groups = [["Details", ["assignee", "responsible", severity.attribute_name]]]
      variant.required_attributes = ["assignee"]
      variant.save!
    end
  end

  shared_let(:mobile) { create(:type_variant, type:, variant_name: "Mobile", workflow: create(:named_workflow)) }
  shared_let(:clone) { create(:type_variant, type:, variant_name: "Clone", workflow: create(:named_workflow)) }
  shared_let(:owned) do
    create(:project_owned_type_variant, type:, project:, variant_name: "Ours", workflow: create(:named_workflow))
  end
  shared_let(:twin) { create(:type_variant, type:, variant_name: "Twin") }

  let(:form) { TypeVariant::FORM_CONFIGURATION }
  let(:index_page) { Pages::Types::Index.new }

  def within_row(section, key, &) = within("#comparison-#{section}-#{key}", &)

  def within_column(variant, &) = within_test_selector("comparison-cell-#{variant.id}", &)

  before do
    create(:status_transition, type_variant: base, role:, old_status: new_status, new_status: closed_status)
    create(:status_transition, type_variant: base, role:, old_status: new_status, new_status: rejected_status)
    create(:status_transition, type_variant: mobile, role:, old_status: new_status, new_status: closed_status)
    create(:status_transition, type_variant: clone, role:, old_status: new_status, new_status: closed_status)

    link_configuration(mobile, aspect: form, excluded: ["responsible"])
    link_configuration(clone, aspect: form, excluded: ["responsible"])
    link_configuration(owned, aspect: form)
    link_configuration(twin, aspect: form)
    owned.update!(required_attributes: base.required_attributes)
    twin.update!(workflow: base.workflow, required_attributes: base.required_attributes)

    login_as(admin)
  end

  it "opens from the type's action menu, and only where there is something to compare" do
    visit types_path

    index_page.within_actions_menu(type) { |menu| menu.find(:menuitem, "Compare variants").click }

    expect(page).to have_current_path(comparison_type_variants_path(type_id: type.id))
    expect(page).to have_test_selector("variant-comparison")

    visit types_path

    index_page.within_actions_menu(plain_type) do |menu|
      expect(menu).to have_no_selector(:menuitem, "Compare variants")
    end
  end

  it "lists every variant of the type as a column, the base one first" do
    visit comparison_type_variants_path(type_id: type.id)

    headers = all("[data-test-selector^='comparison-column-']").map { it.text.downcase }

    expect(headers.first).to include("bug")
    expect(headers.join(" ")).to include("clone").and include("mobile").and include("ours")
  end

  it "counts what each variant's form presents" do
    visit comparison_type_variants_path(type_id: type.id)

    within_row(:form, :fields) do
      within_column(base) { expect(page).to have_text("3") }
      within_column(mobile) { expect(page).to have_text("2") }
    end

    within_row(:form, :required) do
      within_column(base) { expect(page).to have_text("Assignee") }
    end
  end

  it "reports how every aspect of every variant is configured" do
    visit comparison_type_variants_path(type_id: type.id)

    TypeVariant::ASPECTS.each do |aspect|
      expect(page).to have_css("#comparison-configuration-#{aspect}")
    end

    expect(page).to have_no_css("#comparison-configuration-#{TypeVariant::FORM_CONFIGURATION}")

    within_row(:configuration, TypeVariant::PDF_EXPORT) do
      within_column(mobile) { expect(page).to have_text(I18n.t("types.edit.overview.mode.manual")) }
    end
  end

  it "marks each aspect that resolves the same as the base variant" do
    visit comparison_type_variants_path(type_id: type.id)

    same = I18n.t("types.comparison.values.same_as_base")
    no = I18n.t(:general_text_No)

    within_row(:form, :same_as_base) do
      within_column(twin) { expect(page).to have_css("[aria-label='#{same}']") }
      within_column(owned) { expect(page).to have_css("[aria-label='#{same}']") }
      within_column(mobile) { expect(page).to have_text(no) }
      within_column(base) { expect(page).to have_no_css("[aria-label='#{same}']") }
      within_column(base) { expect(page).to have_no_text(no) }
    end

    within_row(:workflows, :same_as_base) do
      within_column(twin) { expect(page).to have_css("[aria-label='#{same}']") }
      within_column(owned) { expect(page).to have_text(no) }
      within_column(mobile) { expect(page).to have_text(no) }
    end
  end

  it "counts the statuses a variant's workflow reaches" do
    visit comparison_type_variants_path(type_id: type.id)

    within_row(:workflows, :statuses) do
      within_column(base) { expect(page).to have_text("3") }
      within_column(mobile) { expect(page).to have_text("2") }
    end
  end

  it "marks variants that resolve to the same configuration" do
    visit comparison_type_variants_path(type_id: type.id)

    duplicate = I18n.t("types.comparison.labels.duplicate")
    same_as_type = I18n.t("types.comparison.labels.same_as_type")

    expect(page).to have_css("[data-test-selector='comparison-column-#{mobile.id}'] .InlineMessage", text: duplicate)
    expect(page).to have_css("[data-test-selector='comparison-column-#{clone.id}'] .InlineMessage", text: duplicate)
    expect(page).to have_no_css("[data-test-selector='comparison-column-#{owned.id}'] .InlineMessage")

    expect(page).to have_css("[data-test-selector='comparison-column-#{twin.id}'] .InlineMessage", text: same_as_type)
    expect(page).to have_no_css("[data-test-selector='comparison-column-#{twin.id}'] .InlineMessage", text: duplicate)
  end

  it "names the project owning a variant" do
    visit comparison_type_variants_path(type_id: type.id)

    within_row(:scope, :availability) do
      within_column(owned) { expect(page).to have_link(project.name) }
      within_column(base) { expect(page).to have_text(I18n.t("types.comparison.values.global")) }
    end
  end

  it "offers nothing to compare on a type without variants" do
    visit comparison_type_variants_path(type_id: plain_type.id)

    expect(page).to have_test_selector("comparison-blankslate")
  end

  it "keeps the page to administration" do
    login_as(create(:user))

    visit comparison_type_variants_path(type_id: type.id)

    expect(page).to have_text(I18n.t(:notice_not_authorized))
    expect(page).to have_no_test_selector("variant-comparison")
  end

  describe "the configuration overview" do
    shared_let(:overview_type) { create(:type, name: "Task") }
    shared_let(:overview_base) { overview_type.default_variant }
    shared_let(:inheriting) { create(:type_variant, type: overview_type, variant_name: "Inheriting") }
    shared_let(:independent) { create(:type_variant, type: overview_type, variant_name: "Independent") }
    shared_let(:project_specific) do
      create(:project_owned_type_variant, type: overview_type, project:, variant_name: "Ours")
    end

    let(:manual) { I18n.t("types.edit.overview.mode.manual") }

    def base_aspect_path(type, aspect)
      case aspect
      when TypeVariant::DEFAULTS then edit_type_defaults_path(type_id: type.id)
      when TypeVariant::PROJECT_ATTRIBUTES then edit_type_project_attributes_path(type_id: type.id)
      else edit_type_pdf_export_template_index_path(type_id: type.id)
      end
    end

    def plain_translation(key, **)
      I18n.t(key, **).gsub(/\[(.+?)\]\(.+?\)/, '\1')
    end

    before do
      TypeVariant::ASPECTS.each { link_configuration(inheriting, aspect: it) }
      link_configuration(project_specific, aspect: TypeVariant::DEFAULTS)

      visit comparison_type_variants_path(type_id: overview_type.id)
    end

    it "names the source of every aspect a variant inherits" do
      TypeVariant::ASPECTS.each do |aspect|
        within_row(:configuration, aspect) do
          within_column(inheriting) do
            expect(page).to have_text(I18n.t("types.comparison.values.inheriting_from"))
            expect(page).to have_link(overview_type.name, href: base_aspect_path(overview_type, aspect))
          end
        end
      end
    end

    it "reports every aspect a variant owns as manually configured" do
      TypeVariant::ASPECTS.each do |aspect|
        within_row(:configuration, aspect) do
          within_column(independent) { expect(page).to have_text(manual) }
          within_column(overview_base) { expect(page).to have_text(manual) }
        end
      end
    end

    it "reports the aspects of a project-specific variant one by one" do
      within_row(:configuration, TypeVariant::DEFAULTS) do
        within_column(project_specific) do
          expect(page).to have_link(overview_type.name, href: base_aspect_path(overview_type, TypeVariant::DEFAULTS))
        end
      end

      (TypeVariant::ASPECTS - [TypeVariant::DEFAULTS]).each do |aspect|
        within_row(:configuration, aspect) do
          within_column(project_specific) { expect(page).to have_text(manual) }
        end
      end
    end

    it "names the owning project of a project-specific variant" do
      within_row(:scope, :availability) do
        within_column(project_specific) do
          expect(page).to have_text(plain_translation("types.comparison.values.project_specific",
                                                      project: project.name))
          expect(page).to have_link(project.name, href: project_settings_work_packages_types_path(project))
        end

        within_column(inheriting) { expect(page).to have_text(I18n.t("types.comparison.values.global")) }
      end
    end
  end
end
