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

class WorkPackages::StatusBadgeComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(status:, **system_arguments)
    super

    @status = status
    @system_arguments = system_arguments

    @highlighted = @system_arguments[:scheme].nil? || @system_arguments[:scheme] == :default
    @system_arguments.delete(:scheme) if @highlighted
  end

  def before_render
    @system_arguments[:classes] = class_names(
      @system_arguments[:classes],
      # The `:secondary` badge carries no status color, but every scheme needs the
      # hook the read-only layout is scoped to.
      (helpers.hl_background_class("status", @status) if @highlighted),
      "op-status-badge",
      "op-status-badge_readonly" => readonly?
    )
  end

  private

  # A read-only status forbids every attribute write except the status itself
  # ({WorkPackages::BaseContract#readonly_attributes_unchanged}), which is not
  # something the badge's colour and name convey on their own. The lock says so,
  # matching the leading visual {WorkPackages::StatusButtonComponent} already
  # gives read-only options in the status dropdown.
  #
  # Read-only statuses are an Enterprise feature, and {Status#is_readonly}
  # answers `false` without the token, so no further gate is needed here.
  #
  # @return [Boolean] whether the status locks the work package.
  def readonly?
    @status.is_readonly?
  end
end
