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
require 'pdf/inspector'

RSpec.describe WorkPackage::PDFExport::WorkPackageToPdf do
  include Redmine::I18n
  let(:type) { create(:type_bug) }
  let(:project) { create(:project, name: 'Foo Bla. Report No. 4/2021 with/for Case 42', types: [type]) }
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: %w[view_work_packages export_work_packages])
  end
  let(:export_time) {
    DateTime.new(2023, 6, 30, 23, 59, 00, '+00:00')
  }
  let(:export_time_formatted) {
    format_time(export_time, true)
  }

  let(:wp) do
    create(:work_package,
           project:,
           type:,
           subject: 'Work package 1',
           story_points: 1,
           description: 'This is a description'
    )
  end
  let(:options) { {} }

  let(:export) do
    login_as(user)
    described_class.new(wp, options)
  end

  let(:export_pdf) do
    Timecop.freeze(export_time) do
      export.export!
    end
  end

  subject(:pdf) do
    PDF::Inspector::Text.analyze(export_pdf.content)
  end

  describe 'with a request for a PDF' do
    it 'contains correct data' do
      expect(pdf.strings).to eq([
                                  "#{type.name} ##{wp.id} - #{wp.subject}",
                                  'ID', wp.id.to_s,
                                  "UPDATED ON", export_time_formatted,
                                  "TYPE", type.name,
                                  "CREATED ON", export_time_formatted,
                                  'STATUS', wp.status.name,
                                  "FINISH DATE",
                                  "VERSION",
                                  "PRIORITY", wp.priority.name,
                                  "DURATION",
                                  "WORK",
                                  "CATEGORY",
                                  "ASSIGNEE",
                                  'Description',
                                  wp.description,
                                  '1', export_time_formatted, project.name
                                ])
    end
  end
end
