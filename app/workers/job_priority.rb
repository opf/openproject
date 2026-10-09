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

module JobPriority
  extend ActiveSupport::Concern

  included do
    # Default to queue with priority 10
    queue_with_priority :default
  end

  class_methods do
    ##
    # Return a priority number on the given payload
    def priority_number(prio = :default)
      case prio
      when :high
        0
      when :notification
        5
      when :above_normal
        7
      when :below_normal
        13
      when :low
        20
      else
        10
      end
    end

    def queue_with_priority(value = :default)
      if value.is_a?(Symbol)
        super(priority_number(value))
      else
        super
      end
    end
  end
end
