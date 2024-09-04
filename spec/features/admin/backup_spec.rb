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

RSpec.describe "backup", :js do
  let(:current_user) do
    create(:user,
           global_permissions: [:create_backup],
           password: user_password,
           password_confirmation: user_password)
  end
  let!(:backup_token) { create(:backup_token, user: current_user) }
  let(:user_password) { "adminadmin!" }

  before do
    @download_list = DownloadList.new

    login_as current_user
  end

  after do
    DownloadList.clear
  end

  subject { @download_list.refresh_from(page).latest_download.to_s }

  it "can be downloaded" do
    visit "/admin/backups"

    fill_in "backupToken", with: backup_token.plain_value
    click_on "Request backup"

    expect(page).to have_content I18n.t("job_status_dialog.generic_messages.in_queue"), wait: 10

    begin
      perform_enqueued_jobs
    rescue StandardError
      # nothing
    end

    expect(page).to have_text I18n.t("export.succeeded"), wait: 10
    expect(subject).to end_with ".zip"
  end

  context "with an error" do
    it "shows the error" do
      visit "/admin/backups"

      fill_in "backupToken", with: "foobar"
      click_on "Request backup"

      expect(page).to have_content I18n.t("backup.error.invalid_token")
    end
  end

  describe "token reset" do
    let(:dialog) { Components::PasswordConfirmationDialog.new }

    before do
      visit "/admin/backups"
      click_on I18n.t("backup.label_reset_token")

      expect(page).to have_content /#{I18n.t('backup.reset_token.heading_reset')}/i

      fill_in "login_verification", with: "reset"
      click_on "Reset"
    end

    it "works given the correct password" do
      dialog.confirm_flow_with(user_password)

      new_token = Token::Backup.find_by(user: current_user)

      expect(new_token.plain_value).not_to eq backup_token.plain_value
      expect(page).to have_content new_token.plain_value
    end

    it "declines the change when an invalid password is given" do
      dialog.confirm_flow_with(user_password + "INVALID", should_fail: true)

      new_token = Token::Backup.find_by_plaintext_value backup_token.plain_value

      expect(new_token).to eq backup_token
    end
  end

  it "allows the backup token to be deleted" do
    visit "/admin/backups"

    expect(page).to have_content /#{I18n.t('js.backup.title')}/i

    click_on I18n.t("backup.label_delete_token")

    page.driver.browser.switch_to.alert.accept

    expect(page).to have_content I18n.t("backup.text_token_deleted")

    token = Token::Backup.find_by(user: current_user)

    expect(token).to be_nil
    expect(page).to have_no_content /#{I18n.t('js.backup.title')}/i
  end
end
