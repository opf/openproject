#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
    create(:type_bug, custom_fields: [cf_long_text, cf_disabled_in_project, cf_global_bool]).tap do |t|
      t.attribute_groups.first.attributes.push(cf_disabled_in_project.attribute_name, cf_long_text.attribute_name)
    end
  end
  let(:parent_project) do
    create(:project, name: "Parent project")
  end
  let(:project) do
    create(:project,
           name: "Foo Bla. Report No. 4/2021 with/for Case 42",
           types: [type],
           public: true,
           status_code: "on_track",
           active: true,
           parent: parent_project,
           work_package_custom_fields: [cf_long_text, cf_disabled_in_project, cf_global_bool],
           work_package_custom_field_ids: [cf_long_text.id, cf_global_bool.id]) # cf_disabled_in_project.id is disabled
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end
  let(:category) { create(:category, project:, name: "Demo") }
  let(:version) { create(:version, project:) }
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, true) }
  let(:image_path) { Rails.root.join("spec/fixtures/files/image.png") }
  let(:priority) { create(:priority_normal) }
  let(:image_attachment) { Attachment.new author: user, file: File.open(image_path) }
  let(:attachments) { [image_attachment] }
  let(:cf_long_text_description) { "foo" }
  let(:cf_long_text) { create(:issue_custom_field, :text, name: "LongText") }
  let!(:cf_disabled_in_project) do
    # NOT enabled by project.work_package_custom_field_ids => NOT in PDF
    create(:float_wp_custom_field, name: "DisabledCustomField")
  end
  let(:cf_global_bool) do
    create(
      :work_package_custom_field,
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
      <p><unknown-tag>Foo</unknown-tag></p>
    DESCRIPTION
  end
  let(:work_package) do
    create(:work_package,
           id: 1,
           project:,
           type:,
           subject: "Work package 1",
           start_date: "2024-05-30",
           due_date: "2024-05-30",
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
             cf_disabled_in_project.id => "6.25",
             cf_global_bool.id => true
           }).tap do |wp|
      allow(wp)
        .to receive(:attachments)
              .and_return attachments
    end
  end
  let(:options) { {} }
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
    exporter.send(:attributes_data_by_wp, work_package)
            .flat_map do |item|
      value = get_column_value(item[:name])
      result = [item[:label].upcase]
      result << value if value.present?
      result
    end
  end

  def get_column_value(column_name)
    formatter = Exports::Register.formatter_for(WorkPackage, column_name, :pdf)
    formatter.format(work_package)
  end

  subject(:pdf) do
    content = export_pdf.content
    # File.binwrite('WorkPackageToPdf-test-preview.pdf', content)
    { strings: PDF::Inspector::Text.analyze(content).strings,
      images: PDF::Inspector::XObject.analyze(content).page_xobjects.flat_map do |o|
        o.values.select { |v| v.hash[:Subtype] == :Image }
      end }
  end

  describe "with a request for a PDF" do
    it "contains correct data" do
      result = pdf[:strings]
      expected_result = [
        "#{type.name} ##{work_package.id} - #{work_package.subject}",
        *expected_details,
        label_title(:description),
        "Lorem", " ", "ipsum", " ", "dolor", " ", "sit", " ",
        "amet", ", consetetur sadipscing elitr.", " ", "@OpenProject Admin",
        "Image Caption",
        "Foo",
        "LongText", "foo",
        "1", export_time_formatted, project.name
      ].flatten
      # Joining the results for comparison since word wrapping leads to a different array for the same content
      expect(result.join(" ")).to eq(expected_result.join(" "))
      expect(result.join(" ")).not_to include("DisabledCustomField")
      expect(pdf[:images].length).to eq(2)
    end

    describe "with embedded attributes" do
      let(:supported_work_package_embeds) do
        [
          ["assignee", user.name],
          ["author", user.name],
          ["category", category.name],
          ["createdAt", export_time_formatted],
          ["updatedAt", export_time_formatted],
          ["estimatedTime", "10.0 h"],
          ["remainingTime", "9.0 h"],
          ["version", version.name],
          ["responsible", user.name],
          ["dueDate", "05/30/2024"],
          ["spentTime", "0.0 h"],
          ["startDate", "05/30/2024"],
          ["parent", "#{type.name} ##{parent_work_package.id}: #{parent_work_package.name}"],
          ["priority", priority.name],
          ["project", project.name],
          ["status", status.name],
          ["subject", "Work package 1"],
          ["type", type.name],
          ["description", "[Rich text embedding currently not supported in export]"]
        ]
      end
      let(:supported_project_embeds) do
        [
          ["active", "Yes"],
          ["description", "[Rich text embedding currently not supported in export]"],
          ["identifier", project.identifier],
          ["name", project.name],
          ["status", I18n.t("activerecord.attributes.project.status_codes.#{project.status_code}")],
          ["statusExplanation", "[Rich text embedding currently not supported in export]"],
          ["parent", parent_project.name],
          ["public", "Yes"]
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
          <table><tbody>#{supported_work_package_embeds_table}</tbody></table>
        DESCRIPTION
      end
      let(:supported_project_embeds_table) do
        supported_project_embeds.map do |embed|
          "<tr><td>projectLabel:#{embed[0]}</td><td>projectValue:#{embed[0]}</td></tr>"
        end
      end
      let(:cf_long_text_description) do
        <<~DESCRIPTION
          ## Project attributes and labels
          <table><tbody>#{supported_project_embeds_table}</tbody></table>
        DESCRIPTION
      end

      it "contains resolved attributes and labels" do
        result = pdf[:strings]
        expected_result = [
          "#{type.name} ##{work_package.id} - #{work_package.subject}",
          *expected_details,
          label_title(:description),
          "Work package attributes and labels",
          supported_work_package_embeds.map do |embed|
            [WorkPackage.human_attribute_name(
              API::Utilities::PropertyNameConverter.to_ar_name(embed[0].to_sym, context: work_package)
            ), embed[1]]
          end,
          "1", export_time_formatted, project.name,
          "LongText",
          "Project attributes and labels",
          supported_project_embeds.map do |embed|
            [Project.human_attribute_name(
              API::Utilities::PropertyNameConverter.to_ar_name(embed[0].to_sym, context: project)
            ), embed[1]]
          end,
          "2", export_time_formatted, project.name
        ].flatten
        # Joining the results for comparison since word wrapping leads to a different array for the same content
        expect(result.join(" ")).to eq(expected_result.join(" "))
      end
    end
  end
end
