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
  class StatusSeeder < Seeder
    def seed_data!
      Status.transaction do
        data.each do |attributes|
          Status.create!(attributes)
        end
      end
    end

    def applicable
      Status.all.any?
    end

    def not_applicable_message
      'Skipping statuses - already exists/configured'
    end

    def data
      color_names = [
        'teal-1', # new
        'indigo-1', # in specification
        'teal-3', # specified
        'red-6', # confirmed
        'yellow-2', # tbs
        'lime-2', # scheduled
        'cyan-3', # in progress
        'cyan-3', # in development
        'teal-6', # developed
        'teal-7', # in testing
        'teal-9', # tested
        'red-9', # test_failed
        'gray-3', # closed
        'orange-3', # on hold
        'red-3', # rejected
      ]

      # When selecting for an array of values, implicit order is applied
      # so we need to restore values by their name.
      colors_by_name = Color.where(name: color_names).index_by(&:name)
      colors = color_names.collect { |name| colors_by_name[name].id }

      [
        { name: I18n.t(:default_status_new),              color_id: colors[0], is_closed: false, is_default: true,  position: 1  },
        { name: I18n.t(:default_status_in_specification), color_id: colors[1], is_closed: false, is_default: false, position: 2  },
        { name: I18n.t(:default_status_specified),        color_id: colors[2], is_closed: false, is_default: false, position: 3  },
        { name: I18n.t(:default_status_confirmed),        color_id: colors[3], is_closed: false, is_default: false, position: 4  },
        { name: I18n.t(:default_status_to_be_scheduled),  color_id: colors[4], is_closed: false, is_default: false, position: 5  },
        { name: I18n.t(:default_status_scheduled),        color_id: colors[5], is_closed: false, is_default: false, position: 6  },
        { name: I18n.t(:default_status_in_progress),      color_id: colors[6], is_closed: false, is_default: false, position: 7  },
        { name: I18n.t(:default_status_in_development),   color_id: colors[7], is_closed: false, is_default: false, position: 8  },
        { name: I18n.t(:default_status_developed),        color_id: colors[8], is_closed: false, is_default: false, position: 9  },
        { name: I18n.t(:default_status_in_testing),       color_id: colors[9], is_closed: false, is_default: false, position: 10 },
        { name: I18n.t(:default_status_tested),           color_id: colors[10], is_closed: false, is_default: false, position: 11 },
        { name: I18n.t(:default_status_test_failed),      color_id: colors[11], is_closed: false, is_default: false, position: 12 },
        { name: I18n.t(:default_status_closed),           color_id: colors[12], is_closed: true,  is_default: false, position: 13 },
        { name: I18n.t(:default_status_on_hold),          color_id: colors[13], is_closed: false, is_default: false, position: 14 },
        { name: I18n.t(:default_status_rejected),         color_id: colors[14], is_closed: true,  is_default: false, position: 15 }
      ]
    end
  end
end
