#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
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
      [
        { name: I18n.t(:default_status_new),              is_closed: false, is_default: true,  position: 1  },
        { name: I18n.t(:default_status_in_specification), is_closed: false, is_default: false, position: 2  },
        { name: I18n.t(:default_status_specified),        is_closed: false, is_default: false, position: 3  },
        { name: I18n.t(:default_status_confirmed),        is_closed: false, is_default: false, position: 4  },
        { name: I18n.t(:default_status_to_be_scheduled),  is_closed: false, is_default: false, position: 5  },
        { name: I18n.t(:default_status_scheduled),        is_closed: false, is_default: false, position: 6  },
        { name: I18n.t(:default_status_in_progress),      is_closed: false, is_default: false, position: 7  },
        { name: I18n.t(:default_status_in_development),   is_closed: false, is_default: false, position: 8  },
        { name: I18n.t(:default_status_developed),        is_closed: false, is_default: false, position: 9  },
        { name: I18n.t(:default_status_in_testing),       is_closed: false, is_default: false, position: 10 },
        { name: I18n.t(:default_status_tested),           is_closed: false, is_default: false, position: 11 },
        { name: I18n.t(:default_status_test_failed),      is_closed: false, is_default: false, position: 12 },
        { name: I18n.t(:default_status_closed),           is_closed: true,  is_default: false, position: 13 },
        { name: I18n.t(:default_status_on_hold),          is_closed: false, is_default: false, position: 14 },
        { name: I18n.t(:default_status_rejected),         is_closed: true,  is_default: false, position: 15 }
      ]
    end
  end
end
