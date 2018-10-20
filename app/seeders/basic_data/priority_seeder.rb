#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
module BasicData
  class PrioritySeeder < Seeder
    def seed_data!
      IssuePriority.transaction do
        data.each do |attributes|
          IssuePriority.create!(attributes)
        end
      end
    end

    def applicable?
      IssuePriority.all.empty?
    end

    def not_applicable_message
      'Skipping priorities as there are already some configured'
    end

    def data
      color_names = [
        'lime-0', # low
        'green-1', # normal
        'yellow-2', # high
        'red-3', # immediate
      ]

      # When selecting for an array of values, implicit order is applied
      # so we need to restore values by their name.
      colors_by_name = Color.where(name: color_names).index_by(&:name)
      colors = color_names.collect { |name| colors_by_name[name].id }

      [
        { name: I18n.t(:default_priority_low),       color_id: colors[0], position: 1, is_default: false },
        { name: I18n.t(:default_priority_normal),    color_id: colors[1], position: 2, is_default: true  },
        { name: I18n.t(:default_priority_high),      color_id: colors[2], position: 3, is_default: false },
        { name: I18n.t(:default_priority_immediate), color_id: colors[3], position: 4, is_default: false }
      ]
    end
  end
end
