#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++
class AdminUserSeeder < Seeder
  def seed_data!
    user = new_admin
    unless user.save! validate: false
      puts 'Seeding admin failed:'
      user.errors.full_messages.each do |msg|
        puts "  #{msg}"
      end
    end
  end

  def applicable?
    User.not_builtin.admin.empty?
  end

  def not_applicable_message
    'No need to seed an admin as there already is one.'
  end

  def new_admin
    User.new.tap do |user|
      user.admin = true
      user.login = 'admin'
      user.password = 'admin'
      user.firstname = 'OpenProject'
      user.lastname = 'Admin'
      user.mail = ENV['ADMIN_EMAIL'].presence || 'admin@example.net'
      user.language = I18n.locale.to_s
      user.status = User.statuses[:active]
      user.force_password_change = force_password_change?
      user.notification_settings.build(channel: :mail, involved: true, mentioned: true, watched: true)
      user.notification_settings.build(channel: :in_app, involved: true, mentioned: true, watched: true)
      user.notification_settings.build(channel: :mail_digest, involved: true, mentioned: true, watched: true)
    end
  end

  def force_password_change?
    Rails.env != 'development' && !force_password_change_disabled?
  end

  def force_password_change_disabled?
    off_values = ["off", "false", "no", "0"]

    off_values.include? ENV[force_password_change_env_switch_name]
  end

  def force_password_change_env_switch_name
    "OP_ADMIN_USER_SEEDER_FORCE_PASSWORD_CHANGE"
  end
end
