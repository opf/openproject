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
require_relative "../exporter/exportable_project_context"

RSpec.describe Projects::Exports::PDF do
  include Redmine::I18n
  include PDFExportSpecUtils

  include_context "with a project with an arrangement of custom fields"
  include_context "with an instance of the described exporter"

  shared_let(:export_time) { DateTime.new(2025, 6, 3, 13, 37) }
  shared_let(:export_time_formatted) { format_date(export_time) }

  let(:export_pdf) do
    Timecop.freeze(export_time) do
      instance.export!
    end
  end

  subject(:pdf) do
    PDF::Inspector::Text.analyze(File.read(export_pdf.content.path)).strings.join(" ")
  end

  def show
    cmd = "open -a Preview #{export_pdf.content.path}"
    `#{cmd}`
  end

  def expected_cover_page
    [
      Setting.app_title,
      query.name,
      User.current.name,
      export_time_formatted
    ]
  end

  it "performs a successful export" do
    expected_document = [
      *expected_cover_page,
      project.name,
      "Description", project.description,
      "Status", I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}"),
      "Public", "No",
      "1/1", export_time_formatted, query.name
    ].join(" ")

    expect(subject).to eq expected_document
  end

  context "with status_explanation enabled" do
    let(:query_columns) { %w[name status_explanation] }

    it "includes the status explanation in the export" do
      expected_document = [
        *expected_cover_page,
        project.name,
        "Status description", "some explanation",
        "1/1", export_time_formatted, query.name
      ].join(" ")

      expect(subject).to eq expected_document
    end
  end

  describe "custom field columns selected" do
    let(:query_columns) do
      %w[id name] + global_project_custom_fields.sort_by(&:name).map(&:column_name)
    end

    context "without view_project_attributes permission" do
      let(:permissions) { super() - %i[view_project_attributes] }
      let(:expected_document) do
        [
          *expected_cover_page,
          project.name,
          "ID", project.id.to_s,
          "1/1", export_time_formatted, query.name
        ].join(" ")
      end

      it "does not include custom field values in the export" do
        expect(subject).to eq expected_document
      end
    end

    context "without export_projects permission" do
      let(:permissions) { %i(view_projects) }
      let(:expected_document) do
        [
          *expected_cover_page,
          "1/1", export_time_formatted, query.name
        ].join(" ")
      end

      it "does not include the project in the export" do
        expect(subject).to eq expected_document
      end
    end

    def get_test_column_value(custom_field)
      case custom_field.field_format
      when "int"
        "5"
      when "version"
        system_version
      when "bool"
        "Yes"
      when "user"
        "Other User"
      when "float"
        "4.5"
      when "text"
        "Some  long  text"
      when "string", "list"
        custom_field.admin_only? ? "hidden" : "Some small text"
      when "date"
        format_date(Time.zone.today)
      when "link"
        "https://www.example.com"
      end
    end

    context "with view_project_attributes permission" do
      let(:expected_document) do
        [
          *expected_cover_page,
          project.name,
          "ID", project.id.to_s,
          *global_project_custom_fields.sort_by(&:name).map { |column| [column.name, get_test_column_value(column)] },
          "1/1", export_time_formatted, query.name
        ].join(" ")
      end

      it "includes custom field values in the export" do
        expect(subject).to eq expected_document
      end
    end

    context "with admin permission" do
      let(:current_user) { build_stubbed(:admin) }
      let(:expected_document) do
        custom_fields = global_project_custom_fields - [not_used_string_cf]
        system_version_project = system_version.project

        [
          *expected_cover_page,

          I18n.t(:label_table_of_contents),
          "1.", "2", project.name,
          "2.", "2", system_version_project.name,
          "1/2", export_time_formatted, query.name,

          "1.", project.name,
          "ID", project.id.to_s,
          *custom_fields.sort_by(&:name).map { |column| [column.name, get_test_column_value(column)] },
          "2.", system_version_project.name,
          "ID", system_version_project.id.to_s,
          "2/2", export_time_formatted, query.name
        ].join(" ")
      end

      it "includes custom field values in the export" do
        expect(subject).to eq expected_document
      end
    end
  end

  describe "custom comment columns selected" do
    let(:query_columns) do
      %w[id name] + global_project_custom_fields.map(&:comment_column_name)
    end

    context "without view_project_attributes permission" do
      let(:permissions) { super() - %i[view_project_attributes] }
      let(:expected_document) do
        [
          *expected_cover_page,
          project.name,
          "ID", project.id.to_s,
          "1/1", export_time_formatted, query.name
        ].join(" ")
      end

      it "does not include custom comments in the export" do
        expect(subject).to eq expected_document
      end
    end

    context "with view_project_attributes permission" do
      let(:expected_document) do
        [
          *expected_cover_page,
          project.name,
          "ID", project.id.to_s,
          "#{version_cf.name} comment", "Comment visible to members",
          "1/1", export_time_formatted, query.name
        ].join(" ")
      end

      it "includes custom comments in the export" do
        expect(subject).to eq expected_document
      end
    end

    context "with admin permission" do
      let(:current_user) { build_stubbed(:admin) }
      let(:expected_document) do
        system_version_project = system_version.project

        [
          *expected_cover_page,

          I18n.t(:label_table_of_contents),
          "1.", "2", project.name,
          "2.", "2", system_version_project.name,
          "1/2", export_time_formatted, query.name,

          "1.", project.name,
          "ID", project.id.to_s,
          "#{version_cf.name} comment", "Comment visible to members",
          "#{hidden_cf.name} comment", "Comment visible to admins",
          "2.", system_version_project.name,
          "ID", system_version_project.id.to_s,
          "2/2", export_time_formatted, query.name
        ].join(" ")
      end

      it "includes custom comments in the export" do
        expect(subject).to eq expected_document
      end

      it "doesn't include unused custom comment" do
        expect(subject).not_to include("#{not_used_string_cf.name} comment")
      end
    end
  end

  context "with no project visible" do
    let(:current_user) { User.anonymous }

    it "does not include the project" do
      expected_document = [
        *expected_cover_page,
        "1/1", export_time_formatted, query.name
      ].join(" ")
      expect(subject).to eq expected_document
    end
  end

  context "with multiple projects" do
    let(:query_columns) { %w[id name] }
    let!(:child_project) do
      create(:project,
             parent: project,
             status_code: "on_track",
             description: "Child project description")
    end

    before do
      login_as current_user
      create(
        :member,
        project: child_project,
        principal: current_user,
        roles: [create(:project_role, permissions: permissions - %i[view_project_attributes])]
      )
    end

    it "includes both projects in the export" do
      expected_document = [
        *expected_cover_page,

        I18n.t(:label_table_of_contents),
        "1.", "2", project.name,
        "1.1.", "2", child_project.name,
        "1/2", export_time_formatted, query.name,

        "1.", project.name,
        "ID", project.id,
        "1.1.", child_project.name,
        "ID", child_project.id,
        "2/2", export_time_formatted, query.name
      ].join(" ")

      expect(subject).to eq expected_document
    end
  end
end
