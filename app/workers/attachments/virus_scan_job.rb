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

module Attachments
  class VirusScanJob < ApplicationJob
    class VirusScanFailed < StandardError; end

    retry_on VirusScanFailed, wait: 5.seconds, attempts: 3
    discard_on ActiveJob::DeserializationError

    queue_with_priority :low

    def perform(attachment)
      return unless Setting::VirusScanning.enabled?
      return unless attachment.status_uploaded?

      User.execute_as(User.system) do
        OpenProject::Mutex.with_advisory_lock_transaction(attachment, 'virus_scan') do
          scan_attachment(attachment)
        end
      end
    rescue StandardError => e
      Rails.logger.error "Error scanning attachment #{attachment.id} for viruses: #{e.message}"
      raise VirusScanFailed.new(e.message)
    end

    private

    def scan_attachment(attachment)
      Rails.logger.debug { "Scanning file #{attachment.id} for viruses." }
      service = Attachments::ClamAVService.new
      response = service.scan(attachment)
      case response
      when ClamAV::SuccessResponse
        handle_success_response(attachment)
      when ClamAV::VirusResponse
        handle_virus_response(attachment, response.virus_name)
      else
        raise VirusScanFailed.new(response&.error_str || "Failed virus scan: #{response.class}")
      end
    end

    def handle_success_response(attachment)
      Rails.logger.warn { "Scanned file #{attachment.id}. No viruses found." }
      attachment.update!(status: :scanned)
    end

    def handle_virus_response(attachment, virus_name)
      action = Setting.antivirus_scan_action
      Rails.logger.warn { "Detected virus #{virus_name} in file #{attachment.id}. Will #{action} the file." }

      if action == :delete
        delete_attachment(attachment)
      else
        quarantine_attachment(attachment)
      end
    end

    def delete_attachment(attachment)
      container = attachment.container
      attachment.destroy!
      create_journal(container, I18n.t('antivirus_scan.deleted_message', filename: attachment.filename))
    end

    def quarantine_attachment(attachment)
      create_journal(attachment.container, I18n.t('antivirus_scan.quarantined_message', filename: attachment.filename))
      attachment.update!(status: :quarantined)
    end

    def create_journal(container, notes)
      return unless container

      ::Journals::CreateService
        .new(container, User.system)
        .call(notes:)
    end
  end
end
