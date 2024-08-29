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

module Attachments
  class VirusRescanJob < VirusScanJob
    queue_with_priority :low

    def perform
      return unless Setting::VirusScanning.enabled?

      User.execute_as(User.system) do
        OpenProject::Mutex.with_advisory_lock(Attachment, "virus_rescan") do
          Attachment.status_rescan.find_each do |attachment|
            scan_attachment(attachment)
          rescue StandardError => e
            Rails.logger.error "Failed to rescan #{attachment.id} for viruses: #{e.message}. Attachment will remain accessible."
          end
        end
      end
      redirect_status
    end

    def redirect_status
      path = ApplicationController.helpers.admin_quarantined_attachments_path
      payload = redirect_payload(path)
      html = I18n.t("settings.antivirus.remaining_scan_complete_html",
                    file_count: I18n.t(:label_x_files, count: Attachment.status_quarantined.count))

      upsert_status(
        status: :success,
        payload: payload.merge(html:)
      )
    end

    def store_status?
      true
    end

    def updates_own_status?
      true
    end
  end
end
