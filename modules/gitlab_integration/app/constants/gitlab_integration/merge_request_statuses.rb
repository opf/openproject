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

module GitlabIntegration
  module MergeRequestStatuses
    OPEN = GitlabStatus.merge_request_status(code: :open,
                                             color: Color.new(hexcode: "#1A7F37"),
                                             icon: :"git-pull-request")
    DRAFT = GitlabStatus.merge_request_status(code: :draft,
                                              color: Color.new(hexcode: "#24292F"),
                                              icon: :"git-pull-request-draft")
    CLOSED = GitlabStatus.merge_request_status(code: :closed,
                                               color: Color.new(hexcode: "#CF222E"),
                                               icon: :"git-pull-request-closed")
    MERGED = GitlabStatus.merge_request_status(code: :merged,
                                               color: Color.new(hexcode: "#8250DF"),
                                               icon: :"git-merge")
    LOCKED = GitlabStatus.merge_request_status(code: :locked,
                                               color: Color.new(hexcode: "#BC4C00"),
                                               icon: :"git-pull-request-locked")

    AVAILABLE = [OPEN, DRAFT, CLOSED, MERGED, LOCKED].freeze
  end
end
