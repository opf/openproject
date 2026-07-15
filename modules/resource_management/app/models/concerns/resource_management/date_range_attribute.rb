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
  # Presents the `start_date`/`end_date` pair as the single joined string the
  # range date picker posts and reads back ("2026-08-01 - 2026-08-14"). Only
  # `start_date`/`end_date` are ever persisted or validated; `date_range` exists
  # so the picker can be bound through the regular attribute assignment used by
  # the SetAttributes services.
  module DateRangeAttribute
    extend ActiveSupport::Concern

    SEPARATOR = " - "

    def date_range
      return "" if start_date.blank? && end_date.blank?

      # A half-open range keeps its separator so that reading the value back in
      # assigns the date to the side it came from.
      [start_date&.iso8601, end_date&.iso8601].join(SEPARATOR)
    end

    def date_range=(value)
      from, to = value.to_s.split(SEPARATOR, 2)

      self.start_date = from.presence
      self.end_date = to.presence
    end
  end
end
