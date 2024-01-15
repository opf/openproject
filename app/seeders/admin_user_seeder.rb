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
class AdminUserSeeder < Seeder
  def seed_data!
    user = new_admin
    if user.save!(validate: false)
      seed_data.store_reference(:openproject_admin, user)
    else
      print_error 'Seeding admin failed:'
      user.errors.full_messages.each do |msg|
        print_error "  #{msg}"
      end
    end
  end

  def applicable?
    User.not_builtin.admin.empty? && !User.exists?(mail: Setting.seed_admin_user_mail)
  end

  def lookup_existing_references
    seed_data.store_reference(:openproject_admin, User.not_builtin.admin.first)
  end

  def not_applicable_message
    'No need to seed an admin as there already is one.'
  end

  def new_admin
    User.new.tap do |user|
      user.admin = true
      user.login = 'admin'
      user.password = Setting.seed_admin_user_password
      first, last = Setting.seed_admin_user_name.split(' ', 2)
      user.firstname = first
      user.lastname = last
      user.mail = Setting.seed_admin_user_mail
      user.language = I18n.locale.to_s
      user.status = User.statuses[:active]
      user.force_password_change = force_password_change?
      user.notification_settings.build(assignee: true, responsible: true, mentioned: true, watched: true)
    end
  end

  def force_password_change?
    return false if Rails.env.development?

    Setting.seed_admin_user_password_reset?
  end
end
