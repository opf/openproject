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
  let(:project) do
    create(:project,
           name: "Foo Bla. Report No. 4/2021 with/for Case 42",
           types: [type],
           work_package_custom_fields: [cf_long_text, cf_disabled_in_project, cf_global_bool],
           work_package_custom_field_ids: [cf_long_text.id, cf_global_bool.id]) # cf_disabled_in_project.id is disabled
  end
  let(:user) do
    create(:user,
           member_with_permissions: { project => %w[view_work_packages export_work_packages] })
  end
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, true) }
  let(:image_path) { Rails.root.join("spec/fixtures/files/image.png") }
  let(:image_attachment) { Attachment.new author: user, file: File.open(image_path) }
  let(:attachments) { [image_attachment] }
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
  let(:work_package) do
    description = <<~DESCRIPTION
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
    create(:work_package,
           project:,
           type:,
           subject: "Work package 1",
           story_points: 1,
           description:,
           custom_values: {
             cf_long_text.id => "foo",
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
      details = exporter.send(:attributes_data_by_wp, work_package)
                        .flat_map do |item|
        value = get_column_value(item[:name])
        result = [item[:label].upcase]
        result << value if value.present?
        result
      end
      # Joining the results for comparison since word wrapping leads to a different array for the same content
      result = pdf[:strings].join(" ")
      expected_result = [
        "#{type.name} ##{work_package.id} - #{work_package.subject}",
        *details,
        label_title(:description),
        "Lorem", " ", "ipsum", " ", "dolor", " ", "sit", " ",
        "amet", ", consetetur sadipscing elitr.", " ", "@OpenProject Admin",
        "Image Caption",
        "Foo",
        "LongText", "foo",
        "1", export_time_formatted, project.name
      ].join(" ")
      expect(result).to eq(expected_result)
      expect(result).not_to include("DisabledCustomField")
      expect(pdf[:images].length).to eq(2)
    end
  end
end
