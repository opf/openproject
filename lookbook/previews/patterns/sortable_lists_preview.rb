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

module Patterns
  # @hidden
  class SortableListsPreview < ViewComponent::Preview
    # Rows drag and the move menu works, but the move URL points at a path
    # that does not exist, so every drop ends in the generic error toast and
    # the rows roll back. Persistence needs a real endpoint.
    # @display min_height 320px
    def single_list
      render_with_template
    end

    # Two lists accepting the same item type under one root. Rows drag
    # between them and the move menu reorders within a list; the request
    # fails for the same reason as in the single list. No action changes
    # list: that keyboard path is the consumer's, see the Sibling lists tab.
    # @display min_height 320px
    def sibling_lists
      render_with_template
    end
  end
end
