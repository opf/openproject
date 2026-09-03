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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::PDFExport::Artefact do
  include Redmine::I18n
  include PDFExportSpecUtils

  let(:type) { create(:type_bug) }
  let(:status) { create(:status, name: "In progress", is_default: true) }
  let(:project) do
    create(:project,
           name: "Artefact project",
           types: [type],
           public: true,
           active: true)
  end
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %w[view_work_packages export_work_packages view_project_attributes]
           })
  end
  let(:work_package) do
    create(:work_package,
           project:,
           type:,
           status:,
           subject: "The artefact subject",
           description: "A **rich** text description")
  end
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:options) { {} }
  let(:exporter) { described_class.new(work_package, options) }
  let(:export_pdf) do
    login_as(user)
    Timecop.freeze(export_time) { exporter.export! }
  end

  subject(:pdf_strings) do
    content = export_pdf.content
    PDF::Inspector::Text.analyze(content).strings
  end

  it "produces a valid PDF" do
    expect(export_pdf).to be_a(Exports::Result)
    expect(export_pdf.content).to start_with("%PDF")
  end

  it "renders the cover heading, subject and description" do
    joined = pdf_strings.join(" ")
    expect(joined).to include("#{type.name} #{work_package.formatted_id}")
    expect(joined).to include(work_package.subject)
    expect(joined).to include(exporter.prawn_badge_text_stuffing(work_package.status.name))
    expect(joined).to include("rich")
  end

  it "builds a filename from the work package attributes" do
    expect(exporter.title).to include(project.identifier)
    expect(exporter.title).to end_with(".pdf")
  end

  describe "project attribute sections" do
    let(:section_a) { create(:project_custom_field_section, name: "Section A") }
    let(:section_b) { create(:project_custom_field_section, name: "Section B") }
    let!(:string_cf) do
      create(:string_project_custom_field,
             name: "Artefact string field",
             projects: [project],
             project_custom_field_section: section_a)
    end
    let!(:bool_cf) do
      create(:boolean_project_custom_field,
             name: "Artefact bool field",
             projects: [project],
             project_custom_field_section: section_b)
    end
    let!(:unmapped_cf) do
      # enabled for the project but not for the work package type => must not appear
      create(:string_project_custom_field,
             name: "Not on this type",
             projects: [project],
             project_custom_field_section: section_a)
    end

    before do
      type.default_variant.project_custom_fields << string_cf
      type.default_variant.project_custom_fields << bool_cf
      project.update!(custom_field_values: { string_cf.id => "Artefact value", bool_cf.id => true })
    end

    it "renders the sections and their project attributes grouped by section" do
      joined = pdf_strings.join(" ")
      expect(joined).to include("Section A", "Section B")
      expect(joined).to include(string_cf.name, "Artefact value")
      expect(joined).to include(bool_cf.name, "Yes")
    end

    it "omits attributes not mapped to the work package type" do
      expect(pdf_strings.join(" ")).not_to include(unmapped_cf.name)
    end
  end

  describe "work package attributes" do
    let(:wp_text_cf) do
      create(:issue_custom_field, :text, name: "WP Long Text CF", is_for_all: true)
    end
    let(:type) { create(:type_bug, custom_fields: [wp_text_cf]) }
    let(:work_package) do
      create(:work_package,
             project:,
             type:,
             status:,
             subject: "The artefact subject",
             description: "A **rich** text description",
             custom_values: { wp_text_cf.id => "The long text value" })
    end

    it "renders work package attributes/custom_fields/wp_tables" do
      joined = pdf_strings.join(" ")
      # standard attribute groups from the work package form configuration
      expect(joined).to include(work_package.type_variant.attribute_groups.first.translated_key)
      # long text custom field label and value
      expect(joined).to include(wp_text_cf.name)
      expect(joined).to include("The long text value")
    end
  end

  describe "embedded query group" do
    let(:embedded_query) do
      create(:global_query,
             column_names: %i[id subject status]).tap do |query|
        query.add_filter("parent", "=", [Queries::Filters::TemplatedValue::KEY])
        query.save!
      end
    end
    let(:child_text_cf) do
      create(:issue_custom_field, :text, name: "Child Long Text CF", is_for_all: true)
    end
    let(:type) do
      create(:type_bug, custom_fields: [child_text_cf]).tap do |t|
        variant = t.default_variant
        variant.attribute_groups = variant.default_attribute_groups +
          [["Related children", [:"query_#{embedded_query.id}"]]]
        variant.save!
      end
    end
    let!(:child_work_package) do
      create(:work_package,
             project:,
             type:,
             status:,
             parent: work_package,
             subject: "The child work package subject",
             description: "The child **description** text",
             custom_values: { child_text_cf.id => "The child long text value" })
    end

    context "as attributes" do
      before do
        allow(exporter).to receive(:query_group_as_table?).and_return(false)
      end

      it "renders the related work packages as attributes with a subject header" do
        joined = pdf_strings.join(" ")
        expect(joined).to include("Related children")
        # the work package name is rendered as header
        expect(joined).to include("The child work package subject")
        # the remaining query columns are rendered as label/value pairs
        expect(joined).to include(WorkPackage.human_attribute_name(:id))
        expect(joined).to include(child_work_package.display_id.to_s)
      end

      it "renders the related work package description and long text custom fields regardless of the query" do
        joined = pdf_strings.join(" ")
        # the description is rendered even though it is not a query column
        expect(joined).to include(WorkPackage.human_attribute_name(:description))
        expect(joined).to include("description")
        # the long text custom field label and value are rendered
        expect(joined).to include(child_text_cf.name)
        expect(joined).to include("The child long text value")
      end
    end

    context "as table" do
      before do
        allow(exporter).to receive(:query_group_as_table?).and_return(true)
      end

      it "renders the related work packages as an embedded table" do
        joined = pdf_strings.join(" ")
        expect(joined).to include("Related children")
        # the query columns are rendered as table header row
        expect(joined).to include(WorkPackage.human_attribute_name(:id))
        # the related work package is rendered as table row
        expect(joined).to include("The child work package subject")
        expect(joined).to include(child_work_package.display_id.to_s)
      end
    end
  end

  describe "project lifecycle" do
    let(:options) { { include_lifecycle: "true" } }
    let(:user) do
      create(:user,
             member_with_permissions: {
               project => %w[view_work_packages export_work_packages view_project_attributes view_project_phases]
             })
    end
    let(:color) { create(:color, name: "Phase color", hexcode: "#123456") }
    let(:definition) do
      create(:project_phase_definition, :with_start_gate,
             name: "Initiation", color:, start_gate_name: "Kickoff approved")
    end
    let!(:phase) do
      create(:project_phase,
             project:,
             definition:,
             start_date: Date.new(2026, 2, 1),
             finish_date: Date.new(2026, 2, 15))
    end

    it "renders the section title, phase name, formatted date range and gate name" do
      joined = pdf_strings.join(" ")
      expect(joined).to include(I18n.t("pdf_generator.dialog.include_lifecycle.label"))
      expect(joined).to include("Initiation")
      expect(joined).to include(format_date(phase.start_date))
      expect(joined).to include(format_date(phase.finish_date))
      expect(joined).to include("Kickoff approved")
    end

    it "adds a table of contents entry for the lifecycle section" do
      expect(pdf_strings.join(" ")).to include(I18n.t(:label_table_of_contents))
    end

    context "when the option is disabled" do
      let(:options) { { include_lifecycle: "false" } }

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_lifecycle.label"))
      end
    end

    context "when the project has no phases with a date range or set gate" do
      let!(:phase) { nil }

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_lifecycle.label"))
      end
    end

    context "when the user cannot view project phases" do
      let(:user) do
        create(:user, member_with_permissions: { project => %w[view_work_packages export_work_packages] })
      end

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_lifecycle.label"))
      end
    end
  end

  describe "project budgets" do
    let(:project) do
      create(:project,
             name: "Artefact project",
             types: [type],
             public: true,
             active: true,
             enabled_module_names: %w[budgets costs])
    end
    let(:permissions) do
      %w[view_work_packages export_work_packages view_project_attributes
         view_budgets view_cost_rates view_hourly_rates]
    end
    let(:user) { create(:user, member_with_permissions: { project => permissions }) }
    let(:options) { { include_budget: "true" } }
    let(:cost_type) { create(:cost_type, name: "API Development") }
    let!(:cost_rate) { create(:cost_rate, cost_type:, rate: 1000.0, valid_from: 1.year.ago.to_date) }
    let(:labor_user) { create(:user, firstname: "Alice", lastname: "Anderson") }
    let!(:hourly_rate) do
      create(:hourly_rate, user: labor_user, project:, rate: 400.0, valid_from: 1.year.ago.to_date)
    end
    let(:budget) { create(:budget, project:, subject: "Phase 1 rollout", fixed_date: Date.current) }
    let!(:material_item) { create(:material_budget_item, budget:, cost_type:, units: 2.0) }
    let!(:labor_item) { create(:labor_budget_item, budget:, principal: labor_user, hours: 15.0) }

    it "renders the section title and the column headers" do
      joined = pdf_strings.join(" ")
      expect(joined).to include(I18n.t("pdf_generator.dialog.include_budget.label"))
      expect(joined).to include(MaterialBudgetItem.human_attribute_name(:units))
      expect(joined).to include(I18n.t("pdf_generator.budgets_table.description"))
      expect(joined).to include(I18n.t("pdf_generator.budgets_table.cost_per_unit"))
      expect(joined).to include(I18n.t("pdf_generator.budgets_table.sum"))
    end

    it "renders the budget heading with its planned total" do
      joined = pdf_strings.join(" ")
      expect(joined).to include("#{budget.id} Phase 1 rollout")
      expect(joined).to include("8,000.00")
    end

    it "renders both cost groups with their line items and subtotals" do
      joined = pdf_strings.join(" ")
      expect(joined).to include(Budget.human_attribute_name(:material_budget))
      expect(joined).to include("2.00")
      expect(joined).to include("API Development")
      expect(joined).to include("1,000.00")
      expect(joined).to include("2,000.00")

      expect(joined).to include(Budget.human_attribute_name(:labor_budget))
      expect(joined).to include("15h")
      expect(joined).to include(labor_user.name)
      expect(joined).to include("400.00")
      expect(joined).to include("6,000.00")
    end

    it "renders labor quantities as abbreviated hours even with the days_and_hours duration format" do
      allow(Setting).to receive(:duration_format).and_return("days_and_hours")
      joined = pdf_strings.join(" ")
      expect(joined).to include("15h")
      expect(joined).not_to include("1d 7h")
    end

    it "adds a table of contents entry for the budgets section" do
      expect(pdf_strings.join(" ")).to include(I18n.t(:label_table_of_contents))
    end

    context "with a second budget" do
      let!(:other_budget) { create(:budget, project:, subject: "Phase 2 rollout", fixed_date: Date.current) }
      let!(:other_material_item) { create(:material_budget_item, budget: other_budget, cost_type:, units: 3.0) }

      it "renders both budgets and a total across them" do
        joined = pdf_strings.join(" ")
        expect(joined).to include("#{budget.id} Phase 1 rollout")
        expect(joined).to include("#{other_budget.id} Phase 2 rollout")
        expect(joined).to include(I18n.t("pdf_generator.budgets_table.total"))
        expect(joined).to include("11,000.00")
      end
    end

    context "when a budget has no unit cost items" do
      let!(:material_item) { nil }

      it "omits the planned unit costs group" do
        joined = pdf_strings.join(" ")
        expect(joined).not_to include(Budget.human_attribute_name(:material_budget))
        expect(joined).to include(Budget.human_attribute_name(:labor_budget))
      end
    end

    context "when an item overrides its calculated costs with a manual amount" do
      let!(:material_item) { create(:material_budget_item, budget:, cost_type:, units: 2.0, amount: 500.0) }

      it "uses the manual amount for the line sum and derives the cost per unit from it" do
        joined = pdf_strings.join(" ")
        expect(joined).to include("500.00")
        expect(joined).to include("250.00")
        expect(joined).not_to include("2,000.00")
      end
    end

    context "when an item has a zero quantity" do
      let!(:material_item) { create(:material_budget_item, budget:, cost_type:, units: 0.0) }

      it "renders the item without a cost per unit" do
        joined = pdf_strings.join(" ")
        expect(joined).to include("API Development")
        expect(joined).not_to include("1,000.00")
      end
    end

    context "when a budget has a base amount" do
      let(:budget) do
        create(:budget, :with_base_amount, project:, subject: "Phase 1 rollout", fixed_date: Date.current)
      end

      it "renders a base amount row so the groups reconcile with the budget total" do
        joined = pdf_strings.join(" ")
        expect(joined).to include(Budget.human_attribute_name(:base_amount))
        expect(joined).to include("250,000.00")
        expect(joined).to include("258,000.00")
      end
    end

    context "when the user cannot view cost rates" do
      let(:permissions) do
        %w[view_work_packages export_work_packages view_project_attributes view_budgets view_hourly_rates]
      end

      it "lists the unit cost items but blanks their amounts and subtotal" do
        joined = pdf_strings.join(" ")
        expect(joined).to include("API Development")
        expect(joined).not_to include("2,000.00")
        expect(joined).to include("6,000.00")
      end
    end

    context "when the user may only view their own hourly rate" do
      let(:permissions) do
        %w[view_work_packages export_work_packages view_project_attributes
           view_budgets view_own_hourly_rate work_package_assigned]
      end
      let(:labor_user) { user }

      it "shows the amount of their own labor cost item" do
        expect(pdf_strings.join(" ")).to include("6,000.00")
      end
    end

    context "when the option is disabled" do
      let(:options) { { include_budget: "false" } }

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_budget.label"))
      end
    end

    context "when the project has no budgets" do
      let(:budget) { nil }
      let!(:material_item) { nil }
      let!(:labor_item) { nil }

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_budget.label"))
      end
    end

    context "when the budgets module is disabled" do
      let(:project) do
        create(:project,
               name: "Artefact project",
               types: [type],
               public: true,
               active: true,
               enabled_module_names: %w[costs])
      end

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_budget.label"))
      end
    end

    context "when the user cannot view budgets" do
      let(:permissions) { %w[view_work_packages export_work_packages] }

      it "does not render the section" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t("pdf_generator.dialog.include_budget.label"))
      end
    end
  end

  describe "table of contents" do
    let(:section) { create(:project_custom_field_section, name: "TOC Section") }
    let!(:string_cf) do
      create(:string_project_custom_field,
             name: "TOC field",
             projects: [project],
             project_custom_field_section: section)
    end

    before do
      type.default_variant.project_custom_fields << string_cf
      project.update!(custom_field_values: { string_cf.id => "TOC value" })
    end

    it "renders a table of contents by default indexing the section headers" do
      joined = pdf_strings.join(" ")
      expect(joined).to include(I18n.t(:label_table_of_contents))
      # the section header appears both in the table of contents and as a section title
      expect(joined.scan("TOC Section").length).to be >= 2
      # a work package attribute group is indexed too
      expect(joined).to include(work_package.type_variant.attribute_groups.first.translated_key)
    end

    it "resolves real page numbers on the second render pass" do
      # the dummy placeholder must have been replaced by real page numbers
      expect(pdf_strings).not_to include(Exports::PDF::Artefact::Toc::TOC_DUMMY_PAGE_NR)
    end

    context "when disabled via the toc option" do
      let(:options) { { toc: "false" } }

      it "does not render a table of contents" do
        expect(pdf_strings.join(" ")).not_to include(I18n.t(:label_table_of_contents))
      end
    end
  end

  describe "linked form configuration", with_flag: { type_variants: true } do
    let(:source_type) do
      create(:type_bug).tap do |t|
        variant = t.default_variant
        variant.attribute_groups = variant.default_attribute_groups + [["borrowed_group", %w(assignee)]]
        variant.save!
      end
    end
    # type_bug is looked up by name (see the factory's initialize_with), so a second
    # plain create(:type_bug) here would resolve to the SAME row as source_type and
    # make link! reject itself as a cycle. A distinct name keeps it a separate type.
    let(:type) do
      create(:type_bug, name: "Bug (linked)").tap do |t|
        link_configuration(t, source: source_type, aspect: TypeVariant::FORM_CONFIGURATION)
      end
    end

    it "renders the source type's groups for the linked type's work package" do
      joined = pdf_strings.join(" ")
      expect(joined).to include(source_type.default_variant.attribute_groups.find { |g|
        g.key == "borrowed_group"
      }.translated_key)
    end
  end

  describe "form configuration when the project resolves a variant", with_flag: { type_variants: true } do
    let(:type) do
      create(:type_bug).tap do |t|
        variant = t.default_variant
        variant.attribute_groups = variant.default_attribute_groups + [["root_group", %w(assignee)]]
        variant.save!
      end
    end
    let(:variant) do
      create(:type_variant, type:, variant_name: "Bug variant").tap do |v|
        unlink_configuration(v, aspect: TypeVariant::FORM_CONFIGURATION)
        v.attribute_groups = v.default_attribute_groups + [["variant_group", %w(assignee)]]
        v.save!
      end
    end
    let(:project) do
      create(:project,
             name: "Artefact project",
             types: [variant],
             public: true,
             active: true)
    end

    def group_caption(owner, key)
      owner.attribute_groups.find { |group| group.key == key }.translated_key
    end

    it "renders the variant's groups" do
      expect(pdf_strings.join(" ")).to include(group_caption(variant, "variant_group"))
    end

    it "does not render the root's groups" do
      expect(pdf_strings.join(" ")).not_to include(group_caption(type.default_variant, "root_group"))
    end
  end
end
