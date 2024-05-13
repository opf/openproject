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
class OAuthApplicationsSeeder < Seeder
  def seed_data!
    call = create_app
    unless call.success?
      print_error "Seeding mobile oauth application failed:"
      call.errors.full_messages.each do |msg|
        print_error "  #{msg}"
      end
    end
  end

  def applicable?
    Doorkeeper::Application.where(builtin: true).empty?
  end

  def not_applicable_message
    "No need to seed oauth appplications as they are already present."
  end

  def create_app
    OAuth::Applications::CreateService
      .new(user: User.system)
      .call(
        enabled: true,
        name: "OpenProject Mobile App",
        redirect_uri: "openprojectapp://oauth-callback",
        builtin: true,
        confidential: false,
        uid: "DgJZ7Rat23xHZbcq_nxPg5RUuxljonLCN7V7N7GoBAA"
      )
  end
end
