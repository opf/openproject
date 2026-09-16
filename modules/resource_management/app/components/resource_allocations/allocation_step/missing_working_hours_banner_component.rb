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
    class MissingWorkingHoursBannerComponent < ApplicationComponent
      include OpTurbo::Streamable

      I18N_SCOPE = "resource_management.allocate_resource_dialog.missing_working_hours"

      def initialize(allocation:)
        super
        @allocation = allocation
      end

      def call
        component_wrapper do
          if unscheduled_range
            render(Primer::Alpha::Banner.new(scheme: :warning, icon: :alert, mt: 2)) { warning_text }
          end
        end
      end

      private

      def user
        @allocation.principal
      end

      def allocation_range
        return if @allocation.start_date.blank? || @allocation.end_date.blank?

        @allocation.start_date..@allocation.end_date
      end

      def unscheduled_range
        return @unscheduled_range if defined?(@unscheduled_range)

        @unscheduled_range =
          if user.present? && allocation_range
            ResourceAllocations::Availability.new(user:).unscheduled_range(allocation_range)
          end
      end

      def warning_text
        if unscheduled_range == allocation_range
          I18n.t("#{I18N_SCOPE}.none")
        else
          I18n.t("#{I18N_SCOPE}.partial", dates: date_range(unscheduled_range))
        end
      end

      def date_range(range)
        "#{helpers.format_date(range.begin)} - #{helpers.format_date(range.end)}"
      end
    end
  end
end
