#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

RSpec.describe WorkPackage::PDFExport::WorkPackageToPdf do
  include Redmine::I18n
  include PDFExportSpecUtils
  let(:type) { create(:type_bug) }
  let(:project) { create(:project, name: 'Foo Bla. Report No. 4/2021 with/for Case 42', types: [type]) }
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %w[view_work_packages export_work_packages])
  end
  let(:export_time) { DateTime.new(2023, 6, 30, 23, 59) }
  let(:export_time_formatted) { format_time(export_time, true) }
  let(:image_path) { Rails.root.join("spec/fixtures/files/image.png") }
  let(:image_attachment) { Attachment.new author: user, file: File.open(image_path) }
  let(:attachments) { [image_attachment] }
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
           subject: 'Work package 1',
           story_points: 1,
           description:).tap do |wp|
      allow(wp)
        .to receive(:attachments)
              .and_return attachments
    end
  end
  let(:options) { {} }
  let(:export) do
    login_as(user)
    described_class.new(work_package, options)
  end
  let(:export_pdf) do
    Timecop.freeze(export_time) do
      export.export!
    end
  end

  subject(:pdf) do
    content = export_pdf.content
    # File.binwrite('WorkPackageToPdf-test-preview.pdf', content)
    { strings: PDF::Inspector::Text.analyze(content).strings,
      images: PDF::Inspector::XObject.analyze(content).page_xobjects.flat_map do |o|
        o.values.select { |v| v.hash[:Subtype] == :Image }
      end }
  end

  describe 'with a request for a PDF' do
    it 'contains correct data' do
      expect(pdf[:strings]).to eq([
                                    "#{type.name} ##{work_package.id} - #{work_package.subject}",
                                    column_title(:id), work_package.id.to_s,
                                    column_title(:updated_at), export_time_formatted,
                                    column_title(:type), type.name,
                                    column_title(:created_at), export_time_formatted,
                                    column_title(:status), work_package.status.name,
                                    column_title(:priority), work_package.priority.name,
                                    label_title(:description),
                                    'Lorem', ' ', 'ipsum', ' ', 'dolor', ' ', 'sit', ' ',
                                    'amet', ', consetetur sadipscing elitr.', ' ', '@OpenProject Admin',
                                    'Image Caption',
                                    'Foo',
                                    '1', export_time_formatted, project.name
                                  ])
      expect(pdf[:images].length).to eq(2)
    end
  end
end
