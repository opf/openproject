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

module OpenProject::Meeting
  module Patches
    module WorkPackagePatch
      extend ActiveSupport::Concern

      included do
        # prepend: true runs the callback before the agenda items and outcomes are nullified,
        # so the meetings referencing the work package can still be found.
        around_destroy :save_meeting_journals, prepend: true, if: -> { meeting_agenda_items.any? || meeting_outcomes.any? }
      end

      private

      def save_meeting_journals
        referencing_meetings = meetings.to_a | Meeting.joins(agenda_items: :outcomes)
                                                      .where(meeting_outcomes: { work_package_id: id })
                                                      .to_a
        yield
        referencing_meetings.each(&:save_journals)
      end
    end
  end
end
