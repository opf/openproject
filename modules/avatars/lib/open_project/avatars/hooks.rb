# frozen_string_literal: true

# OpenProject Avatars plugin
#
# Copyright (C) the OpenProject GmbH
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

module OpenProject
  module Avatars
    class Hooks < ::OpenProject::Hook::ViewListener
      # Renders the avatar management section at the top of the user
      # administration "Details" tab, where it used to live in its own tab.
      render_on :view_users_general_top,
                partial: "avatars/users/avatar_section"

      # Renders the avatar management section at the top of the my/account page,
      # where it replaces the former standalone "Avatar" my-menu page.
      render_on :view_my_account_top,
                partial: "avatars/my/avatar_section"
    end
  end
end
