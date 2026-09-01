# frozen_string_literal: true

require "spec_helper"
require "spreadsheet"
require "models/projects/exporter/exportable_project_context"

RSpec.describe XlsExport::Project::Exporter::XLS do
  include_context "with a project with an arrangement of custom fields"
  include_context "with an instance of the described exporter"

  let(:sheet) do
    io = StringIO.new output
    Spreadsheet.open(io).worksheets.first
  end

  let(:header) { sheet.rows.first.compact } # raw values have trailing nil
  let(:rows) { sheet.rows.drop(1) }

  describe "empty result" do
    before do
      allow(instance).to receive(:records).and_return([])
    end

    it "returns an empty XLS" do
      expect(sheet.rows.count).to eq 1
      expect(rows).to be_empty
    end
  end

  it "performs a successful export" do
    expect(rows.count).to eq(1)
    expect(sheet.row(1)).to eq [project.name, project.description, "Off track", false]
  end

  context "with project description containing html" do
    before do
      project.update_column(:description, "This is an <p>html</p> description.")
    end

    it "performs a successful export" do
      expect(rows.count).to eq(1)
      expect(sheet.row(1)).to eq [project.name, "This is an html description.", "Off track", false]
    end
  end

  context "with status_explanation enabled" do
    let(:query_columns) { %w[name description project_status status_explanation public] }

    it "performs a successful export" do
      expect(rows.count).to eq(1)
      expect(sheet.row(1)).to eq [project.name, project.description,
                                  "Off track", project.status_explanation, false]
    end
  end

  context "with id and identifier enabled" do
    let(:query_columns) { %w[name description project_status public id identifier] }

    it "performs a successful export" do
      expect(rows.count).to eq(1)
      expect(sheet.row(1).to_a).to eq [project.name, project.description, "Off track",
                                       false, project.id, project.identifier]
    end
  end

  context "with typed columns" do
    let(:query_columns) { %w[name id created_at] }

    it "writes them as native values with a matching cell format" do
      name, id, created_at = sheet.row(1).to_a

      expect(name).to eq(project.name)
      expect(id).to eq(project.id)
      expect(created_at).to be_a(DateTime)
      expect(created_at.strftime("%Y-%m-%d %H:%M:%S"))
        .to eq(project.created_at.in_time_zone(User.current.time_zone).strftime("%Y-%m-%d %H:%M:%S"))

      expect(sheet.row(1).format(1).number_format).to eq("0")
      expect(sheet.row(1).format(2).number_format).to eq(Exports::Formatters::XLS::DateFormat.datetime)
    end
  end

  describe "custom field columns selected" do
    let(:query_columns) { %w[name description project_status public] + global_project_custom_fields.map(&:column_name) }

    context "with admin permission" do
      let(:current_user) { build_stubbed(:admin) }

      it "renders all those columns" do
        cf_names = global_project_custom_fields.map(&:name)
        expect(header).to eq ["Name", "Description", "Status", "Public", *cf_names]

        expect(header).to include not_used_string_cf.name
        expect(header).to include hidden_cf.name

        custom_values = global_project_custom_fields.map do |cf|
          case cf
          when bool_cf
            true
          when text_cf, int_cf, float_cf, date_cf
            project.typed_custom_value_for(cf)
          when not_used_string_cf
            nil
          else
            project.formatted_custom_value_for(cf)
          end
        end

        expect(sheet.row(1).to_a)
          .to eq [project.name, project.description, "Off track", false, *custom_values]

        # The column for the project-level-disabled custom field is blank
        expect(sheet.row(1)[header.index(not_used_string_cf.name)]).to be_nil
      end
    end

    context "with view_project_attributes permission" do
      it "renders available project custom fields in the header if enabled in any project" do
        cf_names = global_project_custom_fields.map(&:name)

        expect(header).to eq ["Name", "Description", "Status", "Public", *cf_names]

        expect(header).not_to include not_used_string_cf.name
        expect(header).not_to include hidden_cf.name

        custom_values = global_project_custom_fields.map do |cf|
          case cf
          when bool_cf
            true
          # numeric and date custom values are exported typed so that excel can
          # sort and calculate on them
          when text_cf, int_cf, float_cf, date_cf
            project.typed_custom_value_for(cf)
          when not_used_string_cf
            nil
          else
            project.formatted_custom_value_for(cf)
          end
        end

        expect(sheet.row(1).to_a)
          .to eq [project.name, project.description, "Off track", false, *custom_values]
      end
    end

    context "without view_project_attributes permission" do
      let(:permissions) { super() - %i[view_project_attributes] }

      it "does not render project custom fields in the header" do
        expect(header).to eq %w[Name Description Status Public]

        expect(sheet.row(1))
          .to eq [project.name, project.description, "Off track", false]
      end
    end
  end

  describe "custom comment columns selected" do
    let(:query_columns) { %w[name description project_status public] + global_project_custom_fields.map(&:comment_column_name) }

    context "with admin permission" do
      let(:current_user) { build_stubbed(:admin) }

      it "renders all comment columns" do
        expect(header).to eq %w[Name Description Status Public] + [version_cf, hidden_cf].map { "#{it.name} comment" }

        expect(sheet.row(1)).to eq [
          project.name,
          project.description,
          "Off track",
          false,
          "Comment visible to members",
          "Comment visible to admins"
        ]
      end
    end

    context "with view_project_attributes permission" do
      it "renders comment columns for available project custom fields" do
        expect(header).to eq %w[Name Description Status Public] + ["#{version_cf.name} comment"]

        expect(sheet.row(1)).to eq [
          project.name,
          project.description,
          "Off track",
          false,
          "Comment visible to members"
        ]
      end
    end

    context "without view_project_attributes permission" do
      let(:permissions) { super() - %i[view_project_attributes] }

      it "does not render custom comment columns" do
        expect(header).to eq %w[Name Description Status Public]

        expect(sheet.row(1)).to eq [
          project.name,
          project.description,
          "Off track",
          false
        ]
      end
    end
  end

  describe "project phase columns selected" do
    shared_let(:phase_definition) { create(:project_phase_definition, name: "Initiation") }
    shared_let(:query_columns) { %w[name description project_status public] + ["project_phase_#{phase_definition.id}"] }

    let!(:project_phase) do
      create(:project_phase, project:, definition: phase_definition,
                             start_date: Date.new(2026, 1, 5), finish_date: Date.new(2026, 1, 20))
    end

    context "with view_project_phases permission" do
      let(:permissions) { super() + %i[view_project_phases] }

      context "and an active phase" do
        it "renders the phase's date range in the row" do
          expect(header).to eq %w[Name Description Status Public Initiation]
          expect(sheet.row(1)).to eq [project.name, project.description, "Off track", false, "01/05/2026 - 01/20/2026"]
        end
      end

      context "and an inactive phase" do
        before { project_phase.update!(active: false) }

        it "renders an empty value while keeping the phase column" do
          expect(header).to eq %w[Name Description Status Public Initiation]
          expect(sheet.row(1)).to eq [project.name, project.description, "Off track", false, nil]
        end
      end

      context "and multiple phase definitions" do
        shared_let(:execution_definition) { create(:project_phase_definition, name: "Execution") }
        shared_let(:closing_definition) { create(:project_phase_definition, name: "Closing") }

        let(:query_columns) do
          %w[name description project_status public] +
            [execution_definition, phase_definition, closing_definition].map { |d| "project_phase_#{d.id}" }
        end

        before do
          create(:project_phase, project:, definition: execution_definition,
                                 start_date: Date.new(2026, 2, 1), finish_date: Date.new(2026, 2, 10))
          create(:project_phase, project:, definition: closing_definition, active: false)
        end

        it "renders each definition's own date range and leaves the ones without an active phase empty" do
          expect(header).to eq %w[Name Description Status Public Execution Initiation Closing]
          expect(sheet.row(1)).to eq [project.name, project.description, "Off track", false,
                                      "02/01/2026 - 02/10/2026", "01/05/2026 - 01/20/2026", nil]
        end
      end
    end

    context "without view_project_phases permission anywhere" do
      it "omits the phase column entirely" do
        expect(header).to eq %w[Name Description Status Public]
        expect(sheet.row(1)).to eq [project.name, project.description, "Off track", false]
      end
    end

    context "with view_project_phases permission in another project only" do
      let(:other_project) { create(:project) }

      before do
        create(:member, user: current_user, project: other_project,
                        roles: [create(:project_role, permissions: %i[view_project_phases])])
      end

      it "renders an empty value for the project where the user lacks the permission" do
        expect(header).to eq %w[Name Description Status Public Initiation]
        expect(sheet.row(1)).to eq [project.name, project.description, "Off track", false, nil]
      end
    end
  end

  context "with no project visible" do
    let(:current_user) { User.anonymous }

    it "does not include the project" do
      expect(output).not_to include project.identifier
      expect(rows).to be_empty
    end
  end
end
