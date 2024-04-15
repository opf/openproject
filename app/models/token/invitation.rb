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

module Token
  class Invitation < Base
    include ExpirableToken

    ##
    # Invitation tokens are valid for a configurable amount of days
    def self.validity_time
      Setting.invitation_expiration_days.days
    end

    ##
    # Don't delete expired invitation tokens. Each user can have at most one anyway
    # and we don't want that one to be deleted. Instead when the user tries to activate
    # their account using the expired token the activation will fail due to it being
    # expired. A new invitation token will be generated which deletes the expired one
    # implicitly.
    def delete_expired_tokens; end
  end
end
