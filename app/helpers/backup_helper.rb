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

module BackupHelper
  ##
  # The idea here is to only allow users, who can confirm their password, to backup
  # OpenProject without delay. Users who can't (since they use Google etc.) have to wait
  # just to make sure no one else accessed the computer to trigger a backup.
  #
  #   A better long-term solution might be to introduce a PIN for sensitive operations
  #   in general. Think the PIN for Windows users or trading passwords in online trade platforms.
  #
  # Also we make sure that in case there is a password that it wasn't just set by a would-be attacker.
  #
  # If OpenProject has just been installed we don't check any of this since there's likely nothing
  # sensitive to backup yet and it would prevent a new admin from trying this feature.
  def allow_instant_backup_for_user?(user, date: instant_backup_threshold_date)
    return true if just_installed_openproject? after: date

    # user doesn't use OpenIDConnect (so can be asked to confirm their password)
    !user.uses_external_authentication? &&
      # user cannot change password in OP (LDAP) or hasn't changed it recently
      (user.passwords.empty? || user.passwords.first.updated_at < date)
  end

  def instant_backup_threshold_date
    DateTime.now - OpenProject::Configuration.backup_initial_waiting_period
  end

  def just_installed_openproject?(after: instant_backup_threshold_date)
    created_at = User.order(created_at: :asc).limit(1).pick(:created_at)

    created_at && created_at >= after
  end

  def create_backup_token(user: current_user)
    token = Token::Backup.create!(user:)

    # activate token right away as user had to confirm password
    date = instant_backup_threshold_date
    if allow_instant_backup_for_user?(user, date:)
      token.update_column :created_at, date
    end

    token
  end

  def notify_user_and_admins(user, backup_token:)
    waiting_period = backup_token.waiting? && OpenProject::Configuration.backup_initial_waiting_period
    users = ([user] + User.admin.active).uniq

    users.each do |recipient|
      UserMailer.backup_token_reset(recipient, user:, waiting_period:).deliver_later
    end
  end
end
