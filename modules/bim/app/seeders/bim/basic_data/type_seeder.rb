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
module Bim
  module BasicData
    class TypeSeeder < ::BasicData::TypeSeeder
      def type_names
        %i[task milestone phase clash issue remark request]
      end

      def type_table
        { # position is_default color_name is_in_roadmap is_milestone type_name
          task: [1, true, 'blue-6', true, false, :default_type_task],
          milestone: [2, true, 'orange-6', false, true, :default_type_milestone],
          phase: [3, true, I18n.t(:default_color_grey), false, false, :default_type_phase],
          issue: [4, true, 'indigo-7', true, false, 'seeders.bim.default_type_issue'],
          remark: [5, true, I18n.t(:default_color_green_dark), true, false, 'seeders.bim.default_type_remark'],
          request: [6, true, 'cyan-7', true, false, 'seeders.bim.default_type_request'],
          clash: [7, true, 'red-8', true, false, 'seeders.bim.default_type_clash']
        }
      end
    end
  end
end
