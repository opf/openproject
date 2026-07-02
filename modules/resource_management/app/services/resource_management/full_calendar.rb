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

module ResourceManagement
  # The FullCalendar wire dialect for the resource-planner timeline feeds. It is
  # the single place that knows FullCalendar treats a range's end as exclusive:
  # the rest of the code speaks in inclusive Ruby date ranges and lets this class
  # shift the boundary in both directions, and owns the JSON shapes the feeds
  # return (resource rows, timed events, background spans).
  class FullCalendar
    class << self
      # Reads FullCalendar's exclusive-end `start`/`end` window params into an
      # inclusive range, or nil when the request carries no window yet.
      def range_from_params(params)
        return if params[:start].blank? || params[:end].blank?

        Date.iso8601(params[:start])..(Date.iso8601(params[:end]) - 1)
      end

      def resource(id:, title:, order:, extended_props:)
        { id:, title:, order:, extendedProps: extended_props }
      end

      def event(resource_id:, range:, id: nil, extended_props: nil, class_names: nil)
        { id:, resourceId: resource_id, **span(range), extendedProps: extended_props, classNames: class_names }
          .compact
      end

      def background(resource_id:, range:, class_names:)
        { resourceId: resource_id, **span(range), display: "background", classNames: class_names }
      end

      private

      # An inclusive range serialized to FullCalendar's { start:, exclusive end: }.
      def span(range)
        { start: range.begin.iso8601, end: (range.end + 1).iso8601 }
      end
    end
  end
end
