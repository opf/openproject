#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    class PropertyNameConverter
      class << self
        WELL_KNOWN_ATTRIBUTE_CONVERSIONS = {
          assigned_to: 'assignee',
          fixed_version: 'version',
          done_ratio: 'percentageDone',
          estimated_hours: 'estimatedTime',
          created_on: 'createdAt',
          updated_on: 'updatedAt',
          remaining_hours: 'remainingTime',
          spent_hours: 'spentTime'
        }

        # Converts the attribute name as refered to by ActiveRecord to a corresponding API-conform
        # attribute name:
        #  * camelCasing the attribute name
        #  * unifying :status and :status_id to 'status' (and other foo_id fields)
        #  * converting totally different attribute names (e.g. createdAt vs createdOn)
        def from_ar_name(attribute)
          attribute = normalize_attribute_name attribute

          special_conversion = WELL_KNOWN_ATTRIBUTE_CONVERSIONS[attribute.to_sym]
          return special_conversion if special_conversion

          # use the generic conversion rules if there is no special conversion
          attribute.camelize(:lower)
        end

        private

        # Unifies different attributes refering to the same thing, especially foreign keys
        # e.g. status_id -> status
        def normalize_attribute_name(attribute)
          attribute.to_s.sub(/(.+)_id\z/, '\1')
        end
      end
    end
  end
end
