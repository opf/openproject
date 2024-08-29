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
#
# Primer's autocomplete displays the ID of a user when selected instead of the name
# this cannot be changed at the moment as the component uses a simple text field which
# can't differentiate between a display and submit value
# thus, we can't use it
# leaving the code here for future reference

module Authors
  class AutocompleteItemComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers

    with_collection_parameter :user

    def initialize(user:)
      super

      @user = user
    end

    def call
      render(
        Primer::Beta::AutoComplete::Item.new(
          value: @user.id
        )
      ) do |component|
        component.with_leading_visual_icon(icon: :person)
        @user.name
      end
    end
  end
end
