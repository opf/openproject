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

module ResourcePlannerViews
  module UserTimeline
    # Renders one allocation's bar content on a user row: the allocated hours and
    # the work package the user is allocated to.
    class AllocationBarComponent < ApplicationComponent
      def initialize(allocation:)
        super
        @allocation = allocation
      end

      private

      attr_reader :allocation

      def hours_label
        t("resource_management.allocation.hours", value: allocation.allocated_hours.round)
      end

      def entity_subject
        allocation.entity.subject
      end

      # The work package's status colour, painted on the bar's top edge. Nil when
      # the status has no colour, in which case the CSS falls back to a muted border.
      def status_style
        hexcode = allocation.entity.status&.color&.hexcode
        "--rm-status-color: #{hexcode}" if hexcode.present?
      end
    end
  end
end
