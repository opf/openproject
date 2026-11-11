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

module WorkPackages
  # A way to deliver a work package comment to people outside of OpenProject.
  # Subclass, override what differs and register an instance with
  # WorkPackages::CommentChannels.
  class CommentChannel
    def key = raise(SubclassResponsibilityError)

    def label = raise(SubclassResponsibilityError)

    def delivered_label = raise(SubclassResponsibilityError)

    def icon = raise(SubclassResponsibilityError)

    def available?(work_package:, user:) = false # rubocop:disable Lint/UnusedMethodArgument

    # Called after the comment was saved. Must not raise when the delivery fails,
    # the comment stays in any case.
    def deliver(_journal) = raise(SubclassResponsibilityError)

    def delivered?(_journal) = false

    def journal_preloads = []
  end
end
