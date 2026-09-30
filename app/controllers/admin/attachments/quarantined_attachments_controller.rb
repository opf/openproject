# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module Attachments
    class QuarantinedAttachmentsController < ApplicationController
      layout "admin"
      before_action :require_admin

      before_action :check_available
      before_action :find_quarantined_attachments

      before_action :find_attachment, only: %i[destroy]

      menu_item :attachments

      def index; end

      def destroy
        container = @attachment.container
        @attachment.destroy!

        create_journal(container,
                       User.system,
                       I18n.t("antivirus_scan.deleted_by_admin", filename: @attachment.filename))

        flash[:notice] = t(:notice_successful_delete)
        redirect_to action: :index, status: :see_other
      end

      private

      def check_available
        return if Setting.antivirus_scan_available?

        render_404
      end

      def create_journal(container, user, notes)
        ::Journals::CreateService
          .new(container, user)
          .call(notes:)
      end

      def find_quarantined_attachments
        @attachments = Attachment
          .status_quarantined
          .includes(:author, :container)
      end

      def find_attachment
        @attachment = @attachments.find(params[:id])
      end
    end
  end
end
