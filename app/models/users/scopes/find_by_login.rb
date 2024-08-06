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

# Find a user account by matching case-insensitive.
module Users::Scopes
  module FindByLogin
    extend ActiveSupport::Concern

    class_methods do
      def by_login(login)
        where(["LOWER(login) = ?", login.to_s.downcase])
      end

      # Find a user scope by matching the exact login and then a case-insensitive
      # version. Exact matches will be given priority.
      def find_by_login(login)
        # First look for an exact match
        user = find_by(login:)
        # Fail over to case-insensitive if none was found
        user || by_login(login).first
      end
    end
  end
end
