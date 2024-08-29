# frozen_string_literal: true

# -- copyright
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
# ++

module JobStatus
  module Dialog
    class BodyComponent < ApplicationComponent
      include Turbo::FramesHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      attr_reader :job

      def initialize(job:)
        super

        @job = job
      end

      def pending_statuses
        ::JobStatus::Status.statuses.slice(:in_queue, :in_process).values
      end

      def error_statuses
        ::JobStatus::Status.statuses.slice(:error, :failure, :cancelled).values
      end

      def success_statuses
        ::JobStatus::Status.statuses.slice(:success).values
      end

      def redirect_url
        job&.payload&.dig("redirect")
      end

      def download_url
        job&.payload&.dig("download")
      end

      def job_errors
        job&.payload&.dig("errors")
      end

      def job_html
        job&.payload&.dig("html")
      end

      def job_errors?
        job_errors.present?
      end

      def pending?
        return false if job.nil? || has_error?

        pending_statuses.include?(job.status)
      end

      def has_error?
        return false if job.nil?

        error_statuses.include?(job.status) || job_errors?
      end

      def mime_type
        job&.payload&.dig("mime_type")
      end

      def mime_type_pdf?
        mime_type == "application/pdf"
      end

      def icon
        return { icon: :"x-circle", color: :danger } if job.nil? || has_error?

        { icon: :"issue-closed", color: :success } if success_statuses.include?(job.status)
      end

      def title
        return I18n.t("job_status_dialog.errors") if job.nil? || has_error?

        job.message || job.payload&.dig("title") || I18n.t("job_status_dialog.title")
      end

      def message
        return I18n.t("job_status_dialog.generic_messages.not_found") if job.nil?

        return I18n.t("job_status_dialog.generic_messages.#{job.status}") if pending?

        return job.message if has_error?

        ""
      end
    end
  end
end
