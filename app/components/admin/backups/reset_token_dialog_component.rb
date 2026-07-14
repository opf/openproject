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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module Backups
    class ResetTokenDialogComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include PasswordHelper
      include BackupHelper

      def initialize(user:, backup_token:)
        super

        @user = user
        @backup_token = backup_token
      end

      private

      def id = "backup-reset-token-dialog"

      def action = @backup_token.present? ? "reset" : "create"

      def title = I18n.t("backup.reset_token.heading_#{action}")

      def confirm_button_text = I18n.t("backup.reset_token.action_#{action}")

      def show_warning? = !allow_instant_backup_for_user?(@user)

      def checkbox_confirmation = I18n.t("backup.reset_token.checkbox_confirmation_#{action}")
    end
  end
end
