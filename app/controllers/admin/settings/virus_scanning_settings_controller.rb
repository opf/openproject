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

module Admin::Settings
  class VirusScanningSettingsController < ::Admin::SettingsController
    menu_item :virus_scanning_settings

    before_action :require_ee
    before_action :check_clamav, only: %i[update], if: -> { scan_enabled? }

    def default_breadcrumb
      t('settings.antivirus.title')
    end

    def av_form
      selected = params.dig(:settings, :antivirus_scan_mode)&.to_sym || :disabled

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(:attachments_av_subform,
                                                    partial: "admin/settings/virus_scanning_settings/av_form",
                                                    locals: { selected: })
        end
      end
    end

    private

    def require_ee
      render('upsale') unless EnterpriseToken.allows_to?(:virus_scanning)
    end

    def mark_unscanned_attachments
      @unscanned_attachments = Attachment.status_uploaded
    end

    def check_clamav
      return if params.dig(:settings, :antivirus_scan_mode) == 'disabled'

      service = ::Attachments::ClamAVService.new(params[:settings][:antivirus_scan_mode].to_sym,
                                                 params[:settings][:antivirus_scan_target])

      service.ping
    rescue StandardError => e
      Rails.logger.error { "Failed to check availability of ClamAV: #{e.message}" }
      flash[:error] = t(:'settings.antivirus.clamav_ping_failed')
      redirect_to action: :show
    end

    def scan_enabled?
      Setting.antivirus_scan_mode != :disabled || params.dig(:settings, :antivirus_scan_mode) != 'disabled'
    end

    def success_callback(_call)
      if Setting.antivirus_scan_mode == :disabled && Attachment.status_quarantined.any?
        remaining_quarantine_warning
      elsif scan_enabled? && Attachment.status_uploaded.any?
        rescan_files
      else
        super
      end
    end

    def rescan_files
      flash[:notice] = t('settings.antivirus.remaining_rescanned_files',
                       file_count: t(:label_x_files, count: Attachment.status_uploaded.count))
      Attachment.status_uploaded.update_all(status: :rescan)

      job = Attachments::VirusRescanJob.perform_later
      redirect_to job_status_path(job.job_id)
    end

    def remaining_quarantine_warning
      flash[:info] = t('settings.antivirus.remaining_quarantined_files_html',
                       link: helpers.link_to(t('antivirus_scan.quarantined_attachments.title'),
                                             admin_quarantined_attachments_path),
                       file_count: t(:label_x_files, count: Attachment.status_quarantined.count))
      redirect_to action: :show
    end
  end
end
