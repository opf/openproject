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

module UserGuideData
  class UsersSeeder < Seeder
    CONTENT_FILE = Rails.root.join("app/seeders/user_guide_data/users.yml")

    def seed_data!
      print_status " ↳ Creating user guide users..."

      users_data.each { create_user(it) }
    end

    def applicable?
      User.where(login: users_data.pluck("login")).none?
    end

    private

    def users_data
      @users_data ||= YAML.load_file(CONTENT_FILE).fetch("users")
    end

    def create_user(data)
      User.new(**data.slice("login", "firstname", "lastname"),
               mail: "#{data['login']}@example.net",
               password: data["login"],
               status: User.statuses[:active],
               language: I18n.locale.to_s,
               force_password_change: false)
        .tap { it.notification_settings.build(assignee: true, responsible: true, mentioned: true, watched: true) }
        .tap { it.pref.avatar_color = data["avatar_color"] }
        .save!(validate: false)
    end
  end
end
