#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
require 'features/work_packages/work_packages_page'

describe 'project export', type: :feature, js: true do
  shared_let(:project1) { FactoryBot.create :project }
  shared_let(:project2) { FactoryBot.create :project }
  shared_let(:admin) { FactoryBot.create :admin }

  let(:index_page) { ::Pages::Projects::Index.new }

  let(:current_user) { admin }

  before do
    @download_list = DownloadList.new

    login_as(current_user)

    index_page.visit!
  end

  after do
    DownloadList.clear
  end

  subject { @download_list.refresh_from(page).latest_downloaded_content }

  def export!(expect_success = true)
    index_page.click_more_menu_item 'Export'
    click_on export_type

    # Expect to get a response regarding queuing
    expect(page).to have_content I18n.t('js.job_status.generic_messages.in_queue'),
                                 wait: 10

    begin
      perform_enqueued_jobs
    rescue StandardError
      # nothing
    end

    if expect_success
      expect(page).to have_text("The export has completed successfully")
    end
  end

  describe 'CSV export' do
    let(:export_type) { 'CSV' }

    it 'exports the visible projects' do
      expect(page).to have_selector('td.name', text: project1.name)

      export!

      expect(subject).to have_text(project1.name)
    end
  end
end
