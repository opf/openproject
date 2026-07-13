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

module ResourceAllocations
  module AllocationStep
    # The inline "outside dates" warning below the date fields. It has its own
    # streamable wrapper so date changes can refresh just this banner instead
    # of the whole form — replacing the form would make Turbo restore focus to
    # the date input afterwards, reopening its date picker.
    class ScheduleViolationBannerComponent < ApplicationComponent
      include OpTurbo::Streamable

      def initialize(allocation:)
        super
        @allocation = allocation
      end

      def call
        component_wrapper do
          if schedule_violation?
            render(Primer::Alpha::Banner.new(scheme: :warning, icon: :alert, mt: 2)) { warning_text }
          end
        end
      end

      private

      def schedule_violation?
        @allocation.schedule_violation.present?
      end

      def warning_text
        I18n.t(
          "resource_management.allocate_resource_dialog.outside_dates.description",
          resource_dates: date_range(@allocation.start_date, @allocation.end_date),
          work_package_dates: date_range(@allocation.entity_start_date, @allocation.entity_due_date)
        )
      end

      def date_range(from_date, to_date)
        "#{format_or_dash(from_date)} - #{format_or_dash(to_date)}"
      end

      def format_or_dash(date)
        date.present? ? helpers.format_date(date) : "—"
      end
    end
  end
end
