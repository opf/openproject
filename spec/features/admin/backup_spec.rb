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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'backup', type: :feature, js: true do
  let(:current_user) { FactoryBot.create :admin }
  let!(:backup_token) { FactoryBot.create :backup_token, user: current_user }

  before do
    @download_list = DownloadList.new

    login_as current_user
  end

  after do
    DownloadList.clear
  end

  subject { @download_list.refresh_from(page).latest_download.to_s }

  it "can be downloaded" do
    visit '/admin/backups'

    fill_in 'backupToken', with: backup_token.plain_value
    click_on "Request backup"

    expect(page).to have_content I18n.t('js.job_status.generic_messages.in_queue'), wait: 10

    begin
      perform_enqueued_jobs
    rescue StandardError
      # nothing
    end

    expect(page).to have_text "The export has completed successfully"
    expect(subject).to end_with ".zip"
  end

  context "with an error" do
    it "shows the error" do
      visit "/admin/backups"

      fill_in 'backupToken', with: "foobar"
      click_on "Request backup"

      expect(page).to have_content I18n.t("backup.error.invalid_token")
    end
  end
end
