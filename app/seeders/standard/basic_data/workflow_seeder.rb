#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
module Standard
  module BasicData
    class WorkflowSeeder < ::BasicData::WorkflowSeeder
      def workflows
        types = Type.all
        types = types.map { |t| { t.name => t.id } }.reduce({}, :merge)

        new              = seed_data.find_reference(:default_status_new)
        in_specification = seed_data.find_reference(:default_status_in_specification)
        specified        = seed_data.find_reference(:default_status_specified)
        confirmed        = seed_data.find_reference(:default_status_confirmed)
        to_be_scheduled  = seed_data.find_reference(:default_status_to_be_scheduled)
        scheduled        = seed_data.find_reference(:default_status_scheduled)
        in_progress      = seed_data.find_reference(:default_status_in_progress)
        developed        = seed_data.find_reference(:default_status_developed)
        in_testing       = seed_data.find_reference(:default_status_in_testing)
        tested           = seed_data.find_reference(:default_status_tested)
        test_failed      = seed_data.find_reference(:default_status_test_failed)
        closed           = seed_data.find_reference(:default_status_closed)
        on_hold          = seed_data.find_reference(:default_status_on_hold)
        rejected         = seed_data.find_reference(:default_status_rejected)

        {
          types[I18n.t(:default_type_task)] => [new, in_progress, on_hold, rejected, closed],
          types[I18n.t(:default_type_milestone)] => [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed],
          types[I18n.t(:default_type_phase)] => [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed],
          types[I18n.t(:default_type_feature)] => [new, in_specification, specified, in_progress, developed, in_testing,
                                                   tested, test_failed, on_hold, rejected, closed],
          types[I18n.t(:default_type_epic)] => [new, in_specification, specified, in_progress, developed, in_testing,
                                                tested, test_failed, on_hold, rejected, closed],
          types[I18n.t(:default_type_user_story)] => [new, in_specification, specified, in_progress, developed, in_testing,
                                                      tested, test_failed, on_hold, rejected, closed],
          types[I18n.t(:default_type_bug)] => [new, confirmed, in_progress, developed, in_testing, tested, test_failed,
                                               on_hold, rejected, closed]
        }
      end

      def type_seeder_class
        ::Standard::BasicData::TypeSeeder
      end
    end
  end
end
