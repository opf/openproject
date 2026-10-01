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
  # Renders how much of a work package's scheduled work is covered by resource
  # allocations: an "12h / 35h" label (allocated / scheduled), a percentage,
  # and a colored bar. Shared by the work package list column and the
  # allocations dialog.
  class ProgressComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(work_package:, allocations:)
      super

      @work_package = work_package
      @allocations = allocations
    end

    # Without scheduled work there is nothing to allocate against (and no
    # sensible denominator), so fall back to the muted placeholder.
    def work_scheduled?
      scheduled_hours.positive?
    end

    private

    attr_reader :work_package, :allocations

    def allocated_hours
      allocations.sum { |allocation| allocation.allocated_time.to_i } / 60.0
    end

    # Total work: the rolled-up value for a parent, falling back to the work
    # package's own estimate for a leaf (where `derived_estimated_hours` is nil).
    def scheduled_hours
      (work_package.derived_estimated_hours || work_package.estimated_hours).to_f
    end

    # Share of the scheduled work covered by allocations. Capped at 100 for the
    # bar width; the raw value still drives the label and over-allocation color.
    def ratio
      return 0 unless work_scheduled?

      ((allocated_hours / scheduled_hours) * 100).round
    end

    def bar_percentage
      ratio.clamp(0, 100)
    end

    def bar_color
      if ratio > 100
        :danger_emphasis
      elsif ratio == 100
        :success_emphasis
      else
        :accent_emphasis
      end
    end

    def summary
      t("resource_management.allocation.summary",
        allocated: hours_label(allocated_hours),
        scheduled: hours_label(scheduled_hours))
    end

    def percentage_label
      helpers.number_to_percentage(ratio, precision: 0)
    end

    def hours_label(hours)
      t("resource_management.allocation.hours",
        value: helpers.number_with_precision(hours, precision: 1, strip_insignificant_zeros: true))
    end

    def no_work_message
      t("resource_management.allocation.no_work")
    end

    def no_work_tooltip_id
      "allocation-no-work-#{work_package.id}"
    end
  end
end
