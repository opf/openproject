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
module StandardSeeder
  module BasicData
    class WorkflowSeeder < ::BasicData::WorkflowSeeder
      def workflows
        types = Type.all
        types = types.map { |t| { t.name => t.id } }.reduce({}, :merge)

        new              = Status.find_by(name: I18n.t(:default_status_new))
        in_specification = Status.find_by(name: I18n.t(:default_status_in_specification))
        specified        = Status.find_by(name: I18n.t(:default_status_specified))
        confirmed        = Status.find_by(name: I18n.t(:default_status_confirmed))
        to_be_scheduled  = Status.find_by(name: I18n.t(:default_status_to_be_scheduled))
        scheduled        = Status.find_by(name: I18n.t(:default_status_scheduled))
        in_progress      = Status.find_by(name: I18n.t(:default_status_in_progress))
        developed        = Status.find_by(name: I18n.t(:default_status_developed))
        in_testing       = Status.find_by(name: I18n.t(:default_status_in_testing))
        tested           = Status.find_by(name: I18n.t(:default_status_tested))
        test_failed      = Status.find_by(name: I18n.t(:default_status_test_failed))
        closed           = Status.find_by(name: I18n.t(:default_status_closed))
        on_hold          = Status.find_by(name: I18n.t(:default_status_on_hold))
        rejected         = Status.find_by(name: I18n.t(:default_status_rejected))

        {
          types[I18n.t(:default_type_task)]       => [new, in_progress, on_hold, rejected, closed],
          types[I18n.t(:default_type_milestone)]  => [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed],
          types[I18n.t(:default_type_phase)]      => [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed],
          types[I18n.t(:default_type_feature)]    => [new, in_specification, specified, in_progress, developed, in_testing, tested, test_failed, on_hold, rejected, closed],
          types[I18n.t(:default_type_epic)]       => [new, in_specification, specified, in_progress, developed, in_testing, tested, test_failed, on_hold, rejected, closed],
          types[I18n.t(:default_type_user_story)] => [new, in_specification, specified, in_progress, developed, in_testing, tested, test_failed, on_hold, rejected, closed],
          types[I18n.t(:default_type_bug)]        => [new, confirmed, in_progress, developed, in_testing, tested, test_failed, on_hold, rejected, closed]
        }
      end

      def type_seeder_class
        ::StandardSeeder::BasicData::TypeSeeder
      end

      def status_seeder_class
        ::StandardSeeder::BasicData::StatusSeeder
      end
    end
  end
end
