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

module DevelopmentData
  # Teams of the development data: groups that are not departments, with members that
  # the seed data names by reference.
  class TeamSeeder < Seeder
    def seed_data!
      print_status "    ↳ Creating teams" do
        seed_data.each("development_teams") do |team_data|
          team = Group.create!(lastname: team_data["name"])
          seed_data.store_reference(team_data["reference"], team)
          add_members(team, team_data)
        end
      end
    end

    def applicable?
      names = Array(seed_data.lookup("development_teams")).pluck("name")
      names.any? && Group.where(lastname: names).none?
    end

    private

    def add_members(team, team_data)
      ids = Array(team_data["members"]).map { |reference| seed_data.find_reference(reference).id }
      return if ids.empty?

      Groups::AddUsersService
        .new(team, current_user: admin_user)
        .call(ids:, send_notifications: false)
        .on_failure { |result| raise result.message }
    end
  end
end
