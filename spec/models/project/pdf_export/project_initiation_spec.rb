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
require "pdf/inspector"
require_relative "../../projects/exporter/exportable_project_context"

RSpec.describe Project::PDFExport::ProjectInitiation do
  include PDFExportSpecUtils
  include ProjectsHelper
  include Redmine::I18n

  include_context "with a project with an arrangement of custom fields"

  let(:exporter) { described_class.new(project) }
  let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_projects view_project_attributes view_work_packages] })
  end
  let(:export_time) { DateTime.new(2025, 11, 13, 13, 37) }
  let(:export_time_formatted) { format_time(export_time) }
  let(:wizard_status) { create(:status, name: "Submitted") }
  let(:status) { create(:status, name: "Approved") }
  let(:work_package) { create(:work_package, project: project, status:) }
  let(:custom_artefact_name_key) { "project_mandate" }
  let(:section_a) { create(:project_custom_field_section, name: "Section A") }
  let(:section_b) { create(:project_custom_field_section, name: "Section B") }
  let(:unset_string_cf) { create(:string_project_custom_field, projects: [project]) }
  let(:disabled_custom_field) { create(:string_project_custom_field, name: "Disabled Field") }
  let(:disabled_mapping) do
    create(:project_custom_field_project_mapping,
           project:,
           project_custom_field: disabled_custom_field,
           creation_wizard: false)
  end
  let(:heading) { project_creation_wizard_name(project) }

  subject do
    result = Timecop.freeze(export_time) do
      exporter.export!
    end
    # If you want to actually see the PDF for debugging, uncomment the following line
    # File.binwrite("project_initiation_spec-preview.pdf", result.content)
    # `open project_initiation_spec-preview.pdf`
    PDF::Inspector::Text.analyze(result.content).strings.join(" ")
  end

  before do
    login_as current_user
  end

  context "with a custom defined name" do
    let(:project) { create(:project, project_creation_wizard_artifact_name: custom_artefact_name_key) }
    let(:current_user) { create(:admin) }
    let(:custom_artefact_name) do
      I18n.t(project.project_creation_wizard_artifact_name,
             default: :project_initiation_request,
             scope: "settings.project_initiation_request.name.options")
    end

    it "uses a fixed pattern for the filename" do
      title_datetime = exporter.send(:title_datetime)
      expect(exporter.title).to eq("#{project.identifier}_#{exporter.sane_filename(custom_artefact_name)}_#{title_datetime}.pdf")
    end

    it "exports a PDF containing project initiation using the custom defined name" do
      expected_document = [
        custom_artefact_name, project.name, Setting.app_title, export_time_formatted, # cover page
        custom_artefact_name,
        project.name,
        "1/1", custom_artefact_name, project.name
      ].join(" ")
      expect(subject).to eq expected_document
    end
  end

  context "with a project attributes" do
    before do
      bool_cf.update!(project_custom_field_section: section_a)
      string_cf.update!(project_custom_field_section: section_a)
      text_cf.update!(project_custom_field_section: section_a)
      link_cf.update!(project_custom_field_section: section_a)
      hidden_cf.update!(project_custom_field_section: section_a)
      unset_string_cf.update!(project_custom_field_section: section_a)
      disabled_custom_field.update!(project_custom_field_section: section_a)

      int_cf.update!(project_custom_field_section: section_b)
      float_cf.update!(project_custom_field_section: section_b)
      date_cf.update!(project_custom_field_section: section_b)
      user_cf.update!(project_custom_field_section: section_b)
      version_cf.update!(project_custom_field_section: section_b)

      disabled_mapping
    end

    let(:expected_document) do
      [
        heading, project.name, Setting.app_title, export_time_formatted, # cover page
        heading,
        project.name,
        "The description of the project",

        "Section A",
        bool_cf.name, "Yes",
        text_cf.name, "Some ", "long", " text",
        string_cf.name, "Some small text",
        link_cf.name, "https://www.example.com",
        unset_string_cf.name, "–",

        "Section B",
        version_cf.name, system_version,
        "#{version_cf.name} comment", "Comment visible to members",
        user_cf.name, "Other User",
        int_cf.name, "5",
        float_cf.name, "4.5",
        date_cf.name, format_date(Time.zone.today),

        "1/1", heading, project.name
      ].join(" ")
    end

    it "exports a PDF containing project initiation with custom attributes grouped by sections" do
      expect(subject).to eq expected_document
    end

    context "as admin" do
      let(:current_user) { build(:admin) }

      let(:expected_document) do
        [
          heading, project.name, Setting.app_title, export_time_formatted, # cover page
          heading,
          project.name,
          "The description of the project",

          "Section A",
          bool_cf.name, "Yes",
          text_cf.name, "Some ", "long", " text",
          string_cf.name, "Some small text",
          hidden_cf.name, "hidden",
          "#{hidden_cf.name} comment", "Comment visible to admins",
          link_cf.name, "https://www.example.com",
          unset_string_cf.name, "–",

          "Section B",
          version_cf.name, system_version,
          "#{version_cf.name} comment", "Comment visible to members",
          user_cf.name, "Other User",
          int_cf.name, "5",
          float_cf.name, "4.5",
          date_cf.name, format_date(Time.zone.today),

          "1/1", heading, project.name
        ].join(" ")
      end

      it "exports a PDF containing project initiation with custom attributes grouped by sections" do
        expect(subject).to eq expected_document
      end
    end
  end

  context "with a status" do
    let(:project) { create(:project, project_creation_wizard_status_when_submitted_id: wizard_status.id) }

    it "uses a fixed pattern for the filename" do
      title_datetime = exporter.send(:title_datetime)
      expect(exporter.title).to eq("#{project.identifier}_#{exporter.sane_filename(heading)}_Submitted_#{title_datetime}.pdf")
    end

    it "exports a PDF containing project initiation using the custom defined name" do
      heading_with_badge = [heading, " ", "    Submitted    "]
      expected_document = [
        *heading_with_badge, project.name, Setting.app_title, export_time_formatted, # cover page
        *heading_with_badge,
        project.name,
        "1/1", heading, project.name
      ].join(" ")
      expect(subject).to eq expected_document
    end
  end

  context "with a work package status" do
    let(:project) { create(:project) }

    before do
      # WorkPackage has to be created within the project so we cannot set it in the `create` call
      project.update!(project_creation_wizard_artifact_work_package_id: work_package.id)
    end

    it "uses a fixed pattern for the filename" do
      title_datetime = exporter.send(:title_datetime)
      expect(exporter.title).to eq("#{project.identifier}_#{exporter.sane_filename(heading)}_Approved_#{title_datetime}.pdf")
    end

    it "exports a PDF containing project initiation using the custom defined name" do
      heading_with_badge = [heading, " ", "    Approved    "]
      expected_document = [
        *heading_with_badge, project.name, Setting.app_title, export_time_formatted, # cover page
        *heading_with_badge,
        project.name,
        "1/1", heading, project.name
      ].join(" ")
      expect(subject).to eq expected_document
    end
  end
end
