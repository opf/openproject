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
require "features/work_packages/work_packages_page"

RSpec.describe "work package export", :js, :selenium do
  let(:project) { create(:project_with_types, types: [type_a, type_b]) }
  let(:export_type) { "CSV" }
  let(:current_user) { create(:admin) }
  let(:type_a) { create(:type, name: "Type A") }
  let(:type_b) { create(:type, name: "Type B") }
  let(:wp1) { create(:work_package, project:, done_ratio: 25, type: type_a) }
  let(:wp2) { create(:work_package, project:, done_ratio: 0, type: type_a) }
  let(:wp3) { create(:work_package, project:, done_ratio: 0, type: type_b) }
  let(:wp4) { create(:work_package, project:, done_ratio: 0, type: type_a) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:settings_menu) { Components::WorkPackages::SettingsMenu.new }
  let(:export_sub_type) { nil }
  let(:default_expected_params) do
    { title: "My custom query title" }
  end
  let(:expected_params) do
    default_expected_params
  end
  let(:expected_mime_type) { anything }
  let(:query) { create(:query, user: current_user, project:, name: "My custom query title") }
  let(:query_columns) { query.displayable_columns.map { |c| c.name.to_s } - ["bcf_thumbnail"] }
  let(:cf_text_a) do
    create(
      :work_package_custom_field,
      id: 42,
      name: "Long text custom field",
      field_format: "text",
      is_for_all: false
    )
  end
  let(:cf_text_b) do
    create(
      :work_package_custom_field,
      id: 43,
      name: "Second lt cf",
      field_format: "text",
      is_for_all: false
    )
  end

  before do
    login_as(current_user)

    service_instance = instance_double(WorkPackages::Exports::ScheduleService)
    allow(WorkPackages::Exports::ScheduleService)
      .to receive(:new)
            .with(user: current_user)
            .and_return(service_instance)

    allow(service_instance)
      .to receive(:call)
            .with(query: anything, mime_type: expected_mime_type, params: has_mandatory_params(expected_params))
            .and_return(ServiceResult.success(result: "uuid of the export job"))

    wp1
    wp2
    wp3
    wp4

    query.column_names = query_columns
    query.save!
  end

  RSpec::Matchers.define :has_mandatory_params do |expected|
    match do |actual|
      expected.count do |key, value|
        actual[key.to_sym] == value
      end == expected.size
    end
  end

  def open_page!(query_target = :query)
    case query_target
    when :query
      wp_table.visit_query query
    when :default
      wp_table.visit_with_params ""
    else
      raise ArgumentError, "query_target must be :query or :default"
    end
    work_packages_page.ensure_loaded
  end

  def show_export_dialog!
    settings_menu.open_and_choose I18n.t("js.toolbar.settings.export")
    expect(page).to have_css("#op-work-packages-export-dialog", wait: 5)
    click_on export_type
    sleep 0.1
  end

  def open_export_dialog!(query_target = :query)
    open_page! query_target
    show_export_dialog!
  end

  def export!
    click_on I18n.t("export.dialog.submit")
    expect(page).to have_no_button(I18n.t("export.dialog.submit"), wait: 1)
  end

  def close_export_dialog!
    expect(page).to have_button(I18n.t("js.button_close"))
    click_on I18n.t("js.button_close")
    expect(page).to have_no_button(I18n.t("js.button_close"))
  end

  def export_and_reopen_dialog!(query_target = :query)
    export!
    close_export_dialog!
    open_export_dialog!(query_target)
  end

  def expect_selected_columns(columns = %w[])
    selected_columns = page.within(".op-draggable-autocomplete--selected") do
      all(".op-draggable-autocomplete--item-text").map(&:text)
    end

    expect(selected_columns).to eq(columns)
  end

  context "with Query options" do
    let(:export_type) { I18n.t("export.dialog.format.options.pdf.label") }
    let(:expected_mime_type) { :pdf }

    before do
      open_export_dialog!
    end

    # these values must be looped through the dialog into the export

    context "with activated options" do
      let(:query) do
        create(
          :query,
          id: 1234,
          user: current_user,
          project:,
          display_sums: true,
          include_subprojects: true,
          show_hierarchies: true,
          name: "My custom query title"
        )
      end
      let(:expected_params) do
        default_expected_params.merge({
                                        query_id: "1234",
                                        showSums: "true",
                                        includeSubprojects: "true",
                                        showHierarchies: "true"
                                      })
      end

      it "starts an export with looped through values" do
        export!
      end
    end

    context "with grouping" do
      let(:query) { create(:query, user: current_user, project:, group_by: "project", name: "My custom query title") }
      let(:expected_params) { default_expected_params.merge({ groupBy: "project" }) }

      it "starts an export grouped" do
        export!
      end
    end
  end

  context "in a split view" do
    before do
      wp_table.visit_query query
      work_packages_page.ensure_loaded
      wp_table.open_split_view(wp1)
    end

    it "opens the dialog and exports" do
      open_export_dialog!
      export!
    end
  end

  context "with CSV export" do
    let(:export_type) { I18n.t("export.dialog.format.options.csv.label") }
    let(:expected_mime_type) { :csv }
    let(:expected_params) { default_expected_params }

    before do
      query.export_settings.delete_all
      open_export_dialog!
    end

    context "with descriptions" do
      let(:expected_params) { default_expected_params.merge({ show_descriptions: "true" }) }

      it "exports a csv" do
        check I18n.t("export.dialog.xls.include_descriptions.label")
        export!
      end
    end

    context "without descriptions" do
      let(:expected_params) { default_expected_params.merge({ show_descriptions: "false" }) }

      it "exports a csv" do
        uncheck I18n.t("export.dialog.xls.include_descriptions.label")
        export!
      end
    end
  end

  context "with a saved query" do
    let!(:query) { create(:query, name: "saved settings query", user: current_user, project:) }
    let(:export_type) { I18n.t("export.dialog.format.options.csv.label") }
    let(:expected_mime_type) { :csv }
    let(:expected_columns) { %w[ID Subject Type Status Assignee Priority] }
    let(:expected_params) do
      default_expected_params.merge(
        {
          title: "saved settings query",
          show_descriptions: "true",
          columns: %w[subject type status assigned_to priority]
        }
      )
    end
    let(:query_columns) do
      query.displayable_columns.filter_map { |c| c.name.to_s if expected_columns.include?(c.name.to_s) }
    end

    before do
      open_export_dialog!
    end

    it "saves the export settings" do
      # Ensure that the option to save export settings is there and both checkboxes are unchecked
      expect(page.find_test_selector("op-work-packages-export-dialog-form-save-export-settings")).not_to be_checked
      expect(page.find_test_selector("show-descriptions-csv")).not_to be_checked
      expect_selected_columns(expected_columns)

      # Save settings and include descriptions
      check I18n.t("export.dialog.save_export_settings.label")
      check I18n.t("export.dialog.xls.include_descriptions.label")
      # Remove the first column
      page.within(".op-draggable-autocomplete--selected") do
        first(".op-draggable-autocomplete--remove-item").click
      end

      export_and_reopen_dialog!
      # Last settings are remembered
      expect(page.find_test_selector("show-descriptions-csv")).to be_checked
      expect(page.find_test_selector("op-work-packages-export-dialog-form-save-export-settings")).to be_checked
      expect_selected_columns(expected_columns - ["ID"])

      # Uncheck both checkboxes again (do not include descriptions, do not save changes)
      uncheck I18n.t("export.dialog.save_export_settings.label")
      uncheck I18n.t("export.dialog.xls.include_descriptions.label")
      # Remove the last column
      page.within(".op-draggable-autocomplete--selected") do
        all(".op-draggable-autocomplete--remove-item").last.click
      end
      # Adjust expectation and export
      expected_params[:show_descriptions] = "false"
      expected_params[:columns].pop
      export_and_reopen_dialog!

      # Last saved settings are restored
      expect(page.find_test_selector("show-descriptions-csv")).to be_checked
      expect(page.find_test_selector("op-work-packages-export-dialog-form-save-export-settings")).to be_checked
      expect_selected_columns(expected_columns - ["ID"])
    end
  end

  context "with an unsaved query" do
    let(:export_type) { I18n.t("export.dialog.format.options.csv.label") }
    let(:expected_mime_type) { :csv }
    let(:expected_params) { default_expected_params.merge({ title: "All open", show_descriptions: "true" }) }

    before do
      open_export_dialog!(:default)
    end

    it "does not offer to save export settings" do
      # There is no save option
      expect(page).not_to have_test_selector("op-work-packages-export-dialog-form-save-export-settings")
      # show_descriptions is unchecked by default
      expect(page.find_test_selector("show-descriptions-csv")).not_to be_checked

      # Check show_descriptions and export, then reopen dialog
      check I18n.t("export.dialog.xls.include_descriptions.label")
      export_and_reopen_dialog!(:default)

      # show_descriptions is still unchecked
      expect(page.find_test_selector("show-descriptions-csv")).not_to be_checked
    end
  end

  context "with default display_subprojects_work_packages and an unsaved query" do
    let(:expected_params) { { includeSubprojects: "false" } }
    let(:project_include) { Components::ProjectIncludeComponent.new }

    before do
      Setting.display_subprojects_work_packages = true
      open_page!(:default)
    end

    it "does apply a disabled include_subprojects option" do
      project_include.toggle!
      project_include.expect_open
      project_include.toggle_include_all_subprojects
      project_include.expect_include_all_subprojects_unchecked
      project_include.click_button("Apply")
      show_export_dialog!
      export!
    end
  end

  context "with XLS export" do
    let(:export_type) { I18n.t("export.dialog.format.options.xls.label") }
    let(:expected_mime_type) { :xls }

    before do
      open_export_dialog!
    end

    context "with relations" do
      let(:expected_params) { default_expected_params.merge({ show_relations: "true" }) }

      it "exports a xls" do
        check I18n.t("export.dialog.xls.include_relations.label")
        export!
      end
    end

    context "without relations" do
      let(:expected_params) { default_expected_params.merge({ show_relations: "false" }) }

      it "exports a xls" do
        uncheck I18n.t("export.dialog.xls.include_relations.label")
        export!
      end
    end

    context "with descriptions" do
      let(:expected_params) { default_expected_params.merge({ show_descriptions: "true" }) }

      it "exports a xls" do
        check I18n.t("export.dialog.xls.include_descriptions.label")
        export!
      end
    end

    context "without descriptions" do
      let(:expected_params) { default_expected_params.merge({ show_descriptions: "false" }) }

      it "exports a xls" do
        uncheck I18n.t("export.dialog.xls.include_descriptions.label")
        export!
      end
    end
  end

  context "with PDF export" do
    let(:expected_mime_type) { :pdf }

    before do
      cf_text_a
      cf_text_b
      open_export_dialog!
    end

    context "as table" do
      let(:export_type) { I18n.t("export.dialog.format.options.pdf.label") }
      let(:export_sub_type) { I18n.t("export.dialog.pdf.export_type.options.table.label") }
      let(:expected_params) { default_expected_params.merge({ pdf_export_type: "table" }) }

      before do
        choose export_sub_type
      end

      it "exports a pdf table" do
        export!
      end

      it "does not export a pdf with no columns" do
        page.within "[data-pdf-export-type='table']" do
          all(".op-draggable-autocomplete--remove-item").each(&:click)
        end
        expect(page).to have_text(I18n.t("export.dialog.columns.input_caption_required"))
        click_on I18n.t("export.dialog.submit")
        expect(page).to have_button(I18n.t("export.dialog.submit")) # form not submitted, button is still there
      end

      context "when exporting grouped by project phase column (regression #65740)" do
        let!(:project_phase_with_gates) do
          create(:project_phase,
                 :with_gated_definition,
                 project: project,
                 start_date: Date.new(2024, 12, 1),
                 finish_date: Date.new(2024, 12, 13))
        end
        let!(:project_phase) do
          create(:project_phase,
                 project:,
                 start_date: Date.new(2024, 12, 1),
                 finish_date: Date.new(2024, 12, 13))
        end

        let(:query) { create(:query, user: current_user, project:, group_by: "project_phase", name: "My custom query title") }
        let(:export_type) { I18n.t("export.dialog.format.options.pdf.label") }
        let(:export_sub_type) { I18n.t("export.dialog.pdf.export_type.options.table.label") }
        let(:expected_params) { default_expected_params.merge({ pdf_export_type: "table", groupBy: "project_phase" }) }
        let(:expected_columns) { %w[ID Subject Type Status Assignee Priority ProjectPhase] }

        before do
          wp1.update!(project_phase_definition_id: project_phase_with_gates.definition_id)
          wp2.update!(project_phase_definition_id: project_phase.definition_id)
        end

        it "exports a pdf table" do
          export!
        end
      end
    end

    context "as report" do
      let(:export_type) { I18n.t("export.dialog.format.options.pdf.label") }
      let(:export_sub_type) { I18n.t("export.dialog.pdf.export_type.options.report.label") }
      let(:default_params_report) { default_expected_params.merge({ pdf_export_type: "report" }) }

      before do
        choose export_sub_type
      end

      context "with long text fields" do
        let(:expected_params) { default_params_report.merge({ long_text_fields: "description 42 43" }) }

        it "exports a pdf report with all long text custom fields by default" do
          export!
        end
      end

      context "with long text fields selection" do
        let(:expected_params) { default_params_report.merge({ long_text_fields: "description #{cf_text_b.id}" }) }

        it "exports a pdf report with all remaining custom fields" do
          # Remove one custom field
          page.within(".op-angular-component[data-id='\"ltf-select-export-pdf-report\"']") do
            find(".op-draggable-autocomplete--item-text", text: "Long text custom field")
              .sibling(".op-draggable-autocomplete--remove-item").click
          end

          # Save export settings, export and reopen dialog
          check I18n.t("export.dialog.save_export_settings.label")
          export_and_reopen_dialog!
          choose export_sub_type

          selected_long_fields = page.within(".op-angular-component[data-id='\"ltf-select-export-pdf-report\"']") do
            all(".op-draggable-autocomplete--item-text").map(&:text)
          end
          # The removed field has been saved
          expect(selected_long_fields).to contain_exactly("Description", cf_text_b.name)
        end
      end

      context "with image" do
        let(:expected_params) { default_params_report.merge({ show_images: "true" }) }

        it "exports a pdf report with image by default" do
          export!
        end

        it "exports a pdf report with checked input" do
          check I18n.t("export.dialog.pdf.include_images.label")
          export!
        end
      end

      context "without images" do
        let(:expected_params) { default_params_report.merge({ show_images: "false" }) }

        it "exports a pdf report with checked input" do
          uncheck I18n.t("export.dialog.pdf.include_images.label")
          export!
        end
      end

      context "with no columns" do
        let(:query_columns) { [] }
        let(:expected_params) do
          default_expected_params.merge({ columns: [""], pdf_export_type: "report", no_columns: "1" })
        end

        it "does export a pdf" do
          page.within "[data-pdf-export-type='report']" do
            all(".op-draggable-autocomplete--remove-item").each(&:click)
          end
          export!
        end
      end
    end

    context "as gantt" do
      let(:export_type) { I18n.t("export.dialog.format.options.pdf.label") }
      let(:export_sub_type) { I18n.t("export.dialog.pdf.export_type.options.gantt.label") }

      context "with EE not active" do
        it "gantt is disabled" do
          expect(page).to have_field("pdf_export_type_gantt", type: "radio", disabled: true)
        end
      end

      context "with EE active", with_ee: %i[gantt_pdf_export] do
        let(:expected_params) { default_expected_params.merge({ pdf_export_type: "gantt" }) }

        before do
          choose export_sub_type
        end

        it "exports a gantt chart pdf" do
          export!
        end

        context "with zoom level" do
          let(:expected_params) { default_expected_params.merge({ pdf_export_type: "gantt", gantt_mode: "week" }) }

          it "exports a pdf gantt chart by weeks" do
            select I18n.t("export.dialog.pdf.gantt_zoom_levels.options.weeks"), from: "gantt_mode", wait: 2
            export!
          end
        end

        context "with column width" do
          let(:expected_params) { default_expected_params.merge({ pdf_export_type: "gantt", gantt_width: "very_wide" }) }

          it "exports a pdf gantt chart by column width" do
            select I18n.t("export.dialog.pdf.column_width.options.very_wide"), from: "gantt_width", wait: 2
            export!
          end
        end

        context "with paper size" do
          let(:expected_params) { default_expected_params.merge({ pdf_export_type: "gantt", paper_size: "A1" }) }

          it "exports a pdf gantt chart in A1" do
            select "A1", from: "paper_size"
            export!
          end
        end
      end
    end
  end
end
