#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++
module Bim
  module BasicData
    class StatusSeeder < ::BasicData::StatusSeeder
      def data
        color_names = [
          'blue-6', # new
          'orange-6', # in progress
          'green-3', # resolved
          'gray-3' # closed
        ]

        # When selecting for an array of values, implicit order is applied
        # so we need to restore values by their name.
        colors_by_name = Color.where(name: color_names).index_by(&:name)
        colors = color_names.collect { |name| colors_by_name[name].id }

        [
          { name: I18n.t(:default_status_new),              color_id: colors[0],  is_closed: false, is_default: true,  position: 1 },
          { name: I18n.t(:default_status_in_progress),      color_id: colors[1],  is_closed: false, is_default: false, position: 2 },
          { name: I18n.t('seeders.bim.default_status_resolved'),         color_id: colors[2], is_closed: false, is_default: false, position: 3 },
          { name: I18n.t(:default_status_closed),           color_id: colors[3], is_closed: true, is_default: false, position: 4 },
        ]
      end
    end
  end
end
