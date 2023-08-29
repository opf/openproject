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
  class CreateContract < ::ModelContract
    include RequiresGlobalPermissionsGuard
    include RequiresNoPendingBackupsGuard
    include RequiresBackupTokenGuard

    attribute :comment
    attribute :creator

    validates :creator, presence: true

    validate :backup_token_not_on_cooldown
    validate :backup_limit

    private

    def required_global_permissions
      [Backup.create_permission]
    end

    def backup_token_not_on_cooldown
      token = find_backup_token

      check_waiting_period token if token.present?
    end

    def check_waiting_period(token)
      if token.waiting?
        valid_at = token.created_at + OpenProject::Configuration.backup_initial_waiting_period
        hours = ((valid_at - Time.zone.now) / 60.0 / 60.0).round

        errors.add :base, :token_cooldown, message: I18n.t("backup.error.token_cooldown", hours:)
      end
    end

    def backup_limit
      limit = OpenProject::Configuration.backup_daily_limit
      if Backup.where("created_at >= ?", Time.zone.today).count > limit
        errors.add :base, :limit_reached, message: I18n.t("backup.error.limit_reached", limit:)
      end
    end
  end
end
