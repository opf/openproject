#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Backups
  class RestoreContract < ::ParamsContract
    validate :backup_exists
    validate :user_allowed_to_restore_backup
    validate :backup_token
    validate :no_pending_backups

    private

    def backup_exists
      if !Backup.exists?(id: params[:backup_id])
        errors.add :base, :not_found, message: I18n.t("label_not_found")
      end
    end

    def backup_token
      token = Token::Backup.find_by_plaintext_value options[:backup_token].to_s # rubocop:disable Rails/DynamicFindBy

      if token.blank? || token.user_id != user.id
        errors.add :base, :invalid_token, message: I18n.t("backup.error.invalid_token")
      end
    end

    def no_pending_backups
      current_backup = Backup.last
      if pending_statuses.include? current_backup&.job_status&.status
        errors.add :base, :backup_pending, message: I18n.t("backup.error.backup_pending")
      end
    end

    def user_allowed_to_restore_backup
      errors.add :base, :error_unauthorized unless user_allowed_to_restore_backup?
    end

    def user_allowed_to_restore_backup?
      user.allowed_to_globally? Backup.restore_permission
    end

    def pending_statuses
      ::JobStatus::Status.statuses.slice(:in_queue, :in_process).values
    end
  end
end
