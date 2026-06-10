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

RSpec.describe WorkPackage::PDFExport::WorkPackageToPdf do
  include Redmine::I18n
  include PDFExportSpecUtils

  let(:type) do
    create(:type_bug,
           custom_fields: [cf_long_text, cf_empty_long_text, cf_disabled_in_project, cf_global_bool, cf_link])
  end
  let(:parent_project) do
    create(:project, name: "Parent project")
  end
  let(:project_custom_field_bool) do
    create(:project_custom_field, :boolean,
           name: "Boolean project custom field")
  end
  let(:project_custom_field_string) do
    create(:project_custom_field, :string,
           name: "Secret string", default_value: "admin eyes only",
           admin_only: true)
  end
  let(:project_custom_field_long_text) do
    create(:project_custom_field, :text,
           name: "Rich text project custom field",
           default_value: "rich text field value with a table <table></table>")
  end
  let(:enabled_module_names) { nil }
  let(:project) do
    create(:project,
           name: "Foo Bla. Report No. 4/2021 with/for Case 42",
           types: [type],
           **(enabled_module_names ? { enabled_module_names: } : {}),
           public: true,
           status_code: "on_track",
           description: "A **rich** text description",
           active: true,
           parent: parent_project,
           custom_field_values: {
             project_custom_field_bool.id => true,
             project_custom_field_long_text.id => "foo"
           },
           work_package_custom_fields: [cf_long_text, cf_empty_long_text, cf_disabled_in_project, cf_global_bool, cf_link],

           # cf_disabled_in_project.id not included == disabled
           work_package_custom_field_ids: [cf_long_text.id, cf_empty_long_text.id, cf_global_bool.id, cf_link.id])
  end
  let(:phase_definition) { create(:project_phase_definition, name: "Test Phase") }
  let!(:project_phase) do
    create(:project_phase, project: project, definition: phase_definition, active: true)
  end
  let(:forbidden_project) do
    create(:project,
           name: "Forbidden project",
           types: [type],
           id: 666,
           identifier: "forbidden-project",
           public: false,
           status_code: "on_track",
           active: true,
           description: "A **rich** text description",
           parent: parent_project,
           work_package_custom_fields: [cf_long_text, cf_empty_long_text, cf_disabled_in_project, cf_global_bool, cf_link],

           # cf_disabled_in_project.id not included == disabled
           work_package_custom_field_ids: [cf_long_text.id, cf_empty_long_text.id, cf_global_bool.id, cf_link.id])
  end
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %w[view_work_packages export_work_packages view_project_attributes view_project_phases]
           })
  end
  let(:another_user) do
    create(:user, firstname: "Secret User")
  end
  let(:category) { create(:category, project:, name: "Demo") }
  let(:version) { create(:version, project:) }
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, include_date: true) }
  let(:export_date_formatted) { format_date(export_time) }
  let(:image_path) { Rails.root.join("spec/fixtures/files/image.png") }
  let(:priority) { create(:priority_normal) }
  let(:image_attachment) { Attachment.new author: user, file: File.open(image_path) }
  let(:image_attachment_elsewhere) { Attachment.new author: user, file: File.open(image_path) }
  let(:attachments) { [image_attachment] }
  let(:cf_long_text_description) { "**foo** *faa*" }
  let(:cf_empty_long_text_description) { "" }
  let(:cf_long_text) do
    create(:issue_custom_field, :text, name: "Work Package Custom Field Long Text")
  end
  let(:cf_link) do
    create(:link_wp_custom_field, :link, name: "My Link")
  end
  let(:cf_empty_long_text) do
    create(:issue_custom_field, :text, name: "Empty Work Package Custom Field Long Text")
  end
  let!(:cf_disabled_in_project) do
    # NOT enabled by project.work_package_custom_field_ids => NOT in PDF
    create(:float_wp_custom_field, name: "DisabledCustomField")
  end
  let(:cf_global_bool) do
    create(
      :work_package_custom_field,
      name: "Work Package Custom Field Boolean",
      field_format: "bool",
      is_for_all: true,
      default_value: true
    )
  end
  let(:status) { create(:status, name: "random", is_default: true) }
  let!(:parent_work_package) { create(:work_package, type:, subject: "Parent wp") }
  let(:description) do
    <<~DESCRIPTION
      **Lorem** _ipsum_ ~~dolor~~ `sit` [amet](https://example.com/), consetetur sadipscing elitr.
      <mention data-text="@OpenProject Admin">@OpenProject Admin</mention>
      ![](/api/v3/attachments/#{image_attachment.id}/content)
      <p class="op-uc-p">
        <figure class="op-uc-figure">
          <div class="op-uc-figure--content">
            <img class="op-uc-image" src="/api/v3/attachments/#{image_attachment.id}/content" alt='"foobar"'>
          </div>
          <figcaption>Image Caption</figcaption>
         </figure>
      </p>
      <figure class="op-uc-figure">
         <div class="op-uc-figure--content">
            <img class="op-uc-image" src="/attachments/#{image_attachment.id}/image.png" alt='"image redirect"'>
         </div>
         <figcaption>Image Redirect</figcaption>
      </figure>
      <p><unknown-tag>Foo</unknown-tag></p>
      <img class="op-uc-image op-uc-image_inline" src="/api/v3/attachments/#{image_attachment_elsewhere.id}/content">
    DESCRIPTION
  end
  let(:work_package) do
    create(:work_package,
           id: 1,
           project:,
           type:,
           subject: "Work package 1",
           start_date: "2024-05-30",
           due_date: "2025-03-13",
           created_at: export_time,
           updated_at: export_time,
           author: user,
           assigned_to: user,
           responsible: user,
           story_points: 1,
           estimated_hours: 10,
           done_ratio: 25,
           remaining_hours: 9,
           parent: parent_work_package,
           priority:,
           version:,
           status:,
           category:,
           description:,
           custom_values: {
             cf_long_text.id => cf_long_text_description,
             cf_empty_long_text.id => cf_empty_long_text_description,
             cf_disabled_in_project.id => "6.25",
             cf_global_bool.id => true,
             cf_link.id => "https://example.com"
           }).tap do |wp|
      allow(wp)
        .to receive(:attachments)
              .and_return attachments
    end
  end
  let(:forbidden_work_package) do
    create(:work_package,
           id: 10,
           project: forbidden_project,
           type:,
           subject: "forbidden Work package",
           start_date: "2024-05-30",
           due_date: "2024-05-30",
           created_at: export_time,
           updated_at: export_time,
           author: another_user,
           assigned_to: another_user)
      .tap do |wp|
      allow(wp)
        .to receive(:attachments)
              .and_return attachments
    end
  end
  let(:options) do
    {
      footer_text: project.name
    }
  end
  let(:exporter) do
    described_class.new(work_package, options)
  end
  let(:export) do
    login_as(user)
    exporter
  end
  let(:export_pdf) do
    Timecop.freeze(export_time) do
      export.export!
    end
  end
  let(:expected_details) do
    [
      "#{type.name} #{work_package.formatted_id} - #{work_package.subject}",
      " ", exporter.prawn_badge_text_stuffing(work_package.status.name.downcase), # badge & padding
      "People",
      "Assignee", user.name,
      "Accountable", user.name,
      "Estimates and progress",
      "Work", "10h",
      "Remaining work", "9h",
      "% Complete", "25%",
      "Spent time", "0h",
      "Story Points", "1",
      "Details",
      "Priority", "Normal",
      *(work_package.sprint.present? ? ["Sprint", work_package.sprint] : ["Sprint"]),
      "Version", work_package.version,
      "Category", work_package.category,
      "Project phase",
      "Date", "05/30/2024 - 03/13/2025",
      "Other",
      "Position", "1",
      "Work Package Custom Field Long Text", "foo   faa",
      "Empty Work Package Custom Field Long Text",
      "Work Package Custom Field Boolean", "Yes",
      "My Link", "https://example.com",
      "Costs",
      "Spent units", "Labor costs", "Unit costs", "Overall costs", "Budget"
    ]
  end

  def get_column_value(column_name)
    formatter = Exports::Register.formatter_for(WorkPackage, column_name, :pdf)
    formatter.format(work_package)
  end

  def remove_pdf_page_footers(strings, nr_of_pages)
    result = strings
    nr_of_pages.times do |page|
      result = result.gsub([" #{page + 1}", export_date_formatted, project.name].join(" "), "")
    end
    result
  end

  subject(:pdf) do
    content = export_pdf.content
    # If you want to actually see the PDF for debugging, uncomment the following line
    # File.binwrite("WorkPackageToPdf-test-preview.pdf", content)
    # `open WorkPackageToPdf-test-preview.pdf`
    page_xobjects = PDF::Inspector::XObject.analyze(content).page_xobjects
    images = page_xobjects.flat_map { |o| o.values.select { |v| v.hash[:Subtype] == :Image } }
    logos = page_xobjects.flat_map do |o|
      o.values.flat_map do |v|
        form_object = v.hash[:Subtype] == :Form ? v.hash.dig(:Resources, :XObject, :I1) : nil
        form_object if form_object&.hash && form_object.hash[:Subtype] == :Image
      end
    end
    { strings: PDF::Inspector::Text.analyze(content).strings,
      logos:,
      images: }
  end

  before do
    image_attachment.save
    image_attachment_elsewhere.save
  end

  describe "with a request for a PDF" do
    describe "with rich text and images" do
      it "contains correct data" do
        # Joining with space for comparison since word wrapping leads to a different array for the same content
        # removing the footer text from the result for comparison, as the number of pages and page breaks are not important
        result = remove_pdf_page_footers(pdf[:strings].join(" "), 2)
        expected_result = [
          *expected_details,
          label_title(:description),
          "Lorem", " ", "ipsum", " ", "dolor", " ", "sit", " ",
          "amet", ", consetetur sadipscing elitr.", " ", "@OpenProject Admin",
          "Image Caption",
          "Image Redirect",
          "Foo"
        ].flatten.join(" ")
        expect(result).to eq(expected_result)
        expect(result).not_to include("DisabledCustomField")
        expect(pdf[:images].length).to eq(4)
      end
    end

    describe "with faulty images" do
      before do
        # simulate a null pointer exception
        # https://appsignal.com/openproject-gmbh/sites/62a6d833d2a5e482c1ef825d/exceptions/incidents/2326/samples/62a6d833d2a5e482c1ef825d-848752493603098719217252846401
        # where attachment data is in the database but the file is missing, corrupted or not accessible
        allow_any_instance_of(Attachment).to receive(:file).and_return(nil) # rubocop:disable RSpec/AnyInstance
      end

      it "still finishes the export" do
        expect(pdf[:images].length).to eq(0)
      end
    end

    describe "with SVG file uploaded with .png extension" do
      let(:svg_content) do
        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg width="600" height="600" xmlns="http://www.w3.org/2000/svg">
          <image href="text:/etc/passwd" width="600" height="600" />
          </svg>
        SVG
      end
      let(:svg_file) { FileHelpers.mock_uploaded_file(name: "test.png", content: svg_content, binary: false) }
      let(:svg_attachment) { Attachment.new author: user, file: svg_file }
      let(:attachments) { [svg_attachment] }
      let(:description) do
        <<~DESCRIPTION
          This work package contains an SVG file uploaded with a .png extension.
          ![](/api/v3/attachments/#{svg_attachment.id}/content)
          <img class="op-uc-image" src="/api/v3/attachments/#{svg_attachment.id}/content" alt="SVG file">
        DESCRIPTION
      end

      before do
        svg_attachment.save
      end

      it "correctly identifies the file as SVG based on content, not filename" do
        expect(svg_attachment.content_type).to eq "image/svg+xml"
        expect(svg_attachment.content_type).not_to eq "image/png"
      end

      it "does not process SVG files in PDF export" do
        expect(pdf[:images].length).to eq(0)
      end

      it "completes the PDF export without errors" do
        result = pdf[:strings].join(" ")
        expect(result).to include("This work package contains an SVG file")
        expect(result).not_to include("/etc/passwd")
        expect(result).not_to include("nobody")
        expect(result).not_to include("root")
      end

      it "does not allow SVG content to be processed by MiniMagick" do
        expect(exporter.send(:pdf_embeddable?, "image/svg+xml")).to be false
        expect(exporter.send(:pdf_embeddable?, "image/png")).to be true
        expect(exporter.send(:pdf_embeddable?, "image/jpeg")).to be true
        expect(exporter.send(:pdf_embeddable?, "image/gif")).to be true
        expect(exporter.send(:pdf_embeddable?, "image/webp")).to be true
      end
    end

    describe "with WebP image attachment" do
      let(:webp_path) { Rails.root.join("spec/fixtures/files/image.webp") }
      let(:webp_attachment) { Attachment.new author: user, file: File.open(webp_path) }
      let(:attachments) { [webp_attachment] }
      let(:description) do
        <<~DESCRIPTION
          This work package contains a WebP image.
          ![](/api/v3/attachments/#{webp_attachment.id}/content)
        DESCRIPTION
      end

      before do
        webp_attachment.save
      end

      it "converts WebP images and includes them in the PDF export" do
        expect(webp_attachment.content_type).to eq "image/webp"
        expect(pdf[:images].length).to eq(1)
      end
    end

    describe "with embedded work package attributes" do
      let(:supported_work_package_embeds) do
        [
          ["assignee", user.name],
          ["author", user.name],
          ["category", category.name],
          ["createdAt", export_time_formatted],
          ["updatedAt", export_time_formatted],
          ["estimatedTime", "10h"],
          ["remainingTime", "9h"],
          ["version", version.name],
          ["responsible", user.name],
          ["dueDate", "03/13/2025"],
          ["spentTime", "0h"],
          ["startDate", "05/30/2024"],
          ["parent", "#{type.name} ##{parent_work_package.id}: #{parent_work_package.name}"],
          ["priority", priority.name],
          ["project", project.name],
          ["status", status.name],
          ["subject", "Work package 1"],
          ["type", type.name],
          ["description", "[#{I18n.t('export.macro.nested_rich_text_unsupported')}]"]
        ]
      end
      let(:supported_work_package_embeds_table) do
        supported_work_package_embeds.map do |embed|
          "<tr><td>workPackageLabel:#{embed[0]}</td><td>workPackageValue:#{embed[0]}</td></tr>"
        end
      end
      let(:description) do
        <<~DESCRIPTION
          ## Work package attributes and labels
          <table><tbody>#{supported_work_package_embeds_table}
            <tr><td>Custom field boolean</td><td>
                workPackageValue:1:"#{cf_global_bool.name}"
            </td></tr>
            <tr><td>Custom field rich text</td><td>
                workPackageValue:1:"#{cf_long_text.name}"
            </td></tr>
            <tr><td>My link in table</td><td>workPackageValue:"#{cf_link.name}"</td></tr>
            <tr><td>No replacement of:</td><td>
                <code>workPackageValue:1:assignee</code>
                <code>workPackageLabel:assignee</code>
            </td></tr>
            </tbody></table>

            `workPackageValue:2:assignee workPackageLabel:assignee`

            ```
            workPackageValue:3:assignee
            workPackageLabel:assignee
            ```

            workPackageValue:"My Link"

            Work package not found:
            workPackageValue:1234567890:assignee
            Access denied:
            workPackageValue:#{forbidden_work_package.id}:assignee
        DESCRIPTION
      end

      def expected_description_first
        [
          "Custom field boolean", I18n.t(:general_text_Yes),
          "Custom field rich text", "foo   faa",
          "My link in table", "https://example.com",
          "No replacement of:", "workPackageValue:1:assignee", "workPackageLabel:assignee",
          "workPackageValue:2:assignee workPackageLabel:assignee",
          "workPackageValue:3:assignee", "workPackageLabel:assignee"
        ]
      end

      def expected_description_second
        [
          "https://example.com",
          "Work package not found:  ",
          "[#{I18n.t('export.macro.error', message:
            I18n.t('export.macro.resource_not_found', resource: 'WorkPackage 1234567890'))}]  ",
          "Access denied:  ",
          "[#{I18n.t('export.macro.error', message:
            I18n.t('export.macro.resource_not_found', resource: "WorkPackage #{forbidden_work_package.id}"))}]"
        ]
      end

      it "contains resolved attributes and labels" do
        # Joining with space for comparison since word wrapping leads to a different array for the same content
        # removing the footer text from the result for comparison, as the number of pages and page breaks are not important
        result = remove_pdf_page_footers(pdf[:strings].join(" "), 3)

        expected_result = [
          *expected_details,
          label_title(:description),
          "Work package attributes and labels",
          supported_work_package_embeds.map do |embed|
            [WorkPackage.human_attribute_name(
              API::Utilities::PropertyNameConverter.to_ar_name(embed[0].to_sym, context: work_package)
            ), embed[1]]
          end,
          *expected_description_first,
          *expected_description_second
        ].flatten.join(" ")
        expect(result).to eq(expected_result)
      end
    end

    describe "with embedded project attributes" do
      let(:supported_project_embeds) do
        [
          ["active", I18n.t(:general_text_Yes)],
          ["description", "A  rich  text description"],
          ["identifier", project.identifier],
          ["name", project.name],
          ["status", I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}"), "statusExplanation"],
          ["parent", parent_project.name],
          ["public", I18n.t(:general_text_Yes)]
        ]
      end
      let(:supported_project_embeds_table) do
        supported_project_embeds.map do |embed|
          "<tr><td>projectLabel:#{embed[0]}</td><td>projectValue:#{embed[0]}</td></tr>"
        end
      end
      let(:description) do
        <<~DESCRIPTION
          ## Project attributes and labels
          <table><tbody>#{supported_project_embeds_table}
          <tr><td>Custom field boolean</td><td>
                projectValue:"#{project_custom_field_bool.name}"
            </td></tr>
            <tr><td>Custom field rich text</td><td>
                projectValue:"#{project_custom_field_long_text.name}"
            </td></tr>
            <tr><td>Custom field hidden</td><td>
                projectValue:"#{project_custom_field_string.name}"
            </td></tr>
            <tr><td>No replacement of:</td><td>
                <code>projectValue:1:status</code>
                <code>projectLabel:status</code>
            </td></tr>
            </tbody></table>

            `projectValue:2:status projectLabel:status`

            ```
            projectValue:3:status
            projectLabel:status
            ```

            Project by identifier:
            projectValue:"#{project.identifier}":active

            Project not found:
            projectValue:1234567890:active
            Access denied:
            projectValue:#{forbidden_project.id}:active
            Access denied by identifier:
            projectValue:"#{forbidden_project.identifier}":active
        DESCRIPTION
      end
      let(:expected_result) do
        [
          *expected_details,
          label_title(:description),
          "Project attributes and labels",
          supported_project_embeds.map do |embed|
            [Project.human_attribute_name(
              API::Utilities::PropertyNameConverter.to_ar_name(embed[0].to_sym, context: project)
            ), embed[1]]
          end,
          "Custom field boolean", I18n.t(:general_text_Yes),
          "Custom field rich text", "foo",
          "Custom field hidden",
          "No replacement of:",
          "projectValue:1:status",
          "projectLabel:status",
          "projectValue:2:status projectLabel:status",
          "projectValue:3:status", "projectLabel:status",
          "Project by identifier:", " ", I18n.t(:general_text_Yes),
          "Project not found:  ",
          "[#{I18n.t('export.macro.error', message:
            I18n.t('export.macro.resource_not_found', resource: 'Project 1234567890'))}]  ",
          "Access denied:  ",
          "[#{I18n.t('export.macro.error', message:
            I18n.t('export.macro.resource_not_found', resource: "Project #{forbidden_project.id}"))}]  ",
          "Access denied by identifier:", " ", "[Macro error, resource not found: Project", "forbidden-project]"
        ].flatten.join(" ")
      end

      it "contains resolved attributes and labels" do
        # Joining with space for comparison since word wrapping leads to a different array for the same content
        # removing the footer text from the result for comparison, as the number of pages and page breaks are not important
        result = remove_pdf_page_footers(pdf[:strings].join(" "), 3)
        expect(result).to eq(expected_result)
      end
    end

    describe "with a logo image" do
      let(:description) { "" }

      describe "default" do
        it "contains the default specified logo image" do
          expect(pdf[:logos].length).to eq(1)
          # Rails.root.join("app/assets/images/logo_openproject.png")
          expect(pdf[:logos].first.hash[:Height]).to eq(150)
          expect(pdf[:logos].first.hash[:Width]).to eq(700)
        end
      end

      describe "custom specified" do
        let(:custom_style) { build(:custom_style_with_export_logo) } # custom style factory

        before do
          allow(CustomStyle).to receive(:current).and_return(custom_style)
        end

        it "contains the custom specified logo image" do
          expect(pdf[:logos].length).to eq(1)
          # Rails.root.join("spec/support/custom_styles/export_logos/export_logo_image.png")
          expect(pdf[:logos].first.hash[:Height]).to eq(30)
          expect(pdf[:logos].first.hash[:Width]).to eq(149)
        end
      end
    end

    context "with the backlogs module enabled" do
      let(:enabled_module_names) { %i[backlogs] }
      let(:sprint) { create(:sprint, name: "Sprint name for export", project:) }

      before do
        work_package.sprint = sprint
        work_package.save!
      end

      it "contains correct data" do
        result = remove_pdf_page_footers(pdf[:strings].join(" "), 2)
        expected_result = [
          *expected_details,
          label_title(:description),
          "Lorem", " ", "ipsum", " ", "dolor", " ", "sit", " ",
          "amet", ", consetetur sadipscing elitr.", " ", "@OpenProject Admin",
          "Image Caption",
          "Image Redirect",
          "Foo"
        ].flatten.join(" ")
        expect(result).to eq(expected_result)
        expect(result).not_to include("DisabledCustomField")
      end
    end
  end
end
