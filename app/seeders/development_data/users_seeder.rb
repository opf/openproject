#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
module DevelopmentData
  class UsersSeeder < Seeder
    def seed_data!
      puts 'Seeding development users ...'
      user_names.each do |login|
        user = new_user login.to_s

        if login == :admin_de
          user.language = 'de'
          user.admin = true
        end

        unless user.save! validate: false
          puts "Seeding #{login} user failed:"
          user.errors.full_messages.each do |msg|
            puts "  #{msg}"
          end
        end
      end
    end

    def applicable?
      !seed_users_disabled? && User.where(login: user_names).count === 0
    end

    def seed_users_disabled?
      off_values = ["off", "false", "no", "0"]

      off_values.include? ENV['OP_DEV_USER_SEEDER_ENABLED']
    end

    def user_names
      %i(reader member project_admin admin_de)
    end

    def not_applicable_message
      msg = 'Not seeding development users.'
      msg << ' seed users disabled through ENV' if seed_users_disabled?

      msg
    end

    def new_user(login)
      User.new.tap do |user|
        user.login = login
        user.password = login
        user.firstname = login.humanize
        user.lastname = 'DEV user'
        user.mail = "#{login}@example.net"
        user.status = User::STATUSES[:active]
        user.language = I18n.locale
        user.force_password_change = false
      end
    end

    def force_password_change?
      Rails.env != 'development' && !force_password_change_disabled?
    end

    def force_password_change_disabled?
      off_values = ["off", "false", "no", "0"]

      off_values.include? ENV[force_password_change_env_switch_name]
    end
  end
end
