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

RSpec.describe "Attachments virus scanning",
               :skip_csrf,
               type: :rails_request do
  shared_let(:admin) { create(:admin) }
  let(:service) { instance_double(Attachments::ClamAVService) }

  before do
    login_as admin
    allow(Attachments::ClamAVService)
      .to receive(:new)
      .and_return(service)

    allow(service).to receive(:ping)
  end

  describe "enabling virus scanning",
           with_ee: %i[virus_scanning] do
    subject do
      patch "/admin/settings/virus_scanning",
            params: {
              settings: {
                antivirus_scan_mode: "clamav_socket"
              }
            }
      response
    end

    it "shows an error if ClamAV cannot be reached" do
      allow(service).to receive(:ping).and_raise(Errno::ECONNREFUSED)

      expect(subject).to be_redirect
      follow_redirect!
      expect(response.body).to have_text I18n.t("settings.antivirus.clamav_ping_failed")
      expect(Setting.antivirus_scan_mode).to eq(:disabled)
    end

    it "shows no error if ClamAV can be reached" do
      expect(subject).to be_redirect
      follow_redirect!
      expect(response.body).to have_no_text I18n.t("settings.antivirus.clamav_ping_failed")
      expect(Setting.antivirus_scan_mode).to eq(:clamav_socket)
    end
  end

  describe "rescanning uploaded files",
           with_ee: %i[virus_scanning] do
    shared_let(:attachment) { create(:attachment, status: :uploaded) }

    it "triggers rescanning of the uploaded files" do
      patch "/admin/settings/virus_scanning",
            params: {
              settings: {
                antivirus_scan_mode: "clamav_socket"
              }
            }

      expect(response).to be_redirect
      follow_redirect!
      expect(response.body).to have_text "This process has been scheduled in the background"
      expect(Setting.antivirus_scan_mode).to eq(:clamav_socket)

      expect(attachment.reload).to be_status_rescan
      expect(Attachments::VirusRescanJob)
        .to have_been_enqueued
    end
  end

  describe "disabling virus scanning",
           with_ee: %i[virus_scanning] do
    shared_let(:attachment) { create(:attachment, status: :quarantined) }

    it "shows no warning if there are no quarantined files" do
      attachment.destroy!
      patch "/admin/settings/virus_scanning",
            params: {
              settings: {
                antivirus_scan_mode: "disabled"
              }
            }

      expect(response).to be_redirect
      follow_redirect!
      expect(response.body).to have_no_text "remain in quarantine."
      expect(Setting.antivirus_scan_mode).to eq(:disabled)
    end

    it "shows a warning if there are still quarantined files" do
      patch "/admin/settings/virus_scanning",
            params: {
              settings: {
                antivirus_scan_mode: "disabled"
              }
            }

      expect(response).to be_redirect
      follow_redirect!
      expect(response.body).to have_text "1 file remain in quarantine."
      expect(Setting.antivirus_scan_mode).to eq(:disabled)
    end
  end

  describe "without ee" do
    it "redirects to upsale" do
      get "/admin/settings/virus_scanning"
      expect(response.body).to have_text "Virus scanning is an Enterprise add-on", normalize_ws: true
    end
  end
end
