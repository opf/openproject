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

module Planner
  # Maps the "Day part" field's options to day parts by position, so renamed or translated options
  # keep their meaning.
  class DayPartField
    DAY_PARTS = %i[morning afternoon evening].freeze

    attr_reader :custom_field

    def self.find
      new(WorkPackageCustomField.for_semantic_key(:day_part))
    end

    def initialize(custom_field)
      @custom_field = custom_field
    end

    def day_part_of(work_package)
      option_id = work_package.custom_value_for(custom_field)&.value.to_i

      DAY_PARTS[option_ids.index(option_id) || 0]
    end

    # Work package attributes that put a task into the given day part.
    def attributes_for(day_part)
      { "custom_field_#{custom_field.id}": option_ids[DAY_PARTS.index(day_part&.to_sym) || 0] }
    end

    private

    def option_ids
      @option_ids ||= custom_field.custom_options.order(:position).pluck(:id)
    end
  end
end
