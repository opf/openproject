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

module WorkPackageTypes
  # The type list has two states to paint once a switch has been queued: one
  # still running, or one that has just settled. Both the switch endpoint and
  # the endpoint the page polls have to paint them the same way.
  module SwitchFeedback
    private

    def render_switch_state(project)
      pending = ::Projects::Types::SwitchStatus.pending_for(project)

      replace_via_turbo_stream(
        component: Projects::Settings::WorkPackages::Types::ListComponent.new(
          project: project.reload,
          pending_switch: pending
        )
      )
      announce_switch_outcome(project) if pending.nil?
    end

    def announce_switch_outcome(project)
      outcome = ::Projects::Types::SwitchStatus.latest_for(project)
      return if outcome.nil?

      if outcome.success?
        render_success_flash_message_via_turbo_stream(message: outcome.message)
      else
        render_error_flash_message_via_turbo_stream(message: outcome.message)
      end
    end
  end
end
