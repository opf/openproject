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

module API
  module V3
    URN_PREFIX = "urn:openproject-org:api:v3:".freeze
    URN_ERROR_PREFIX = "#{URN_PREFIX}errors:".freeze
    # For resources invisible to the user, a resource (including a payload) will contain
    # an "undisclosed uri" instead of a url. This indicates the existence of a value
    # without revealing anything. An example for this is the parent project which might be
    # invisible to a user.
    # In case a "undisclosed uri" is provided as a link, the current value is not
    # to be altered and thus it is treated as if the value where never provided in
    # the first place. This allows a schema/_embedded/payload -> client -> POST/PUT
    # request/response round trip where the user knows of the existence of the value without revealing
    # the contents. The payload remains valid in this case and the client can distinguish between
    # keeping the value and unsetting the linked resource to null.
    URN_UNDISCLOSED = "#{URN_PREFIX}undisclosed".freeze
  end
end
