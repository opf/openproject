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
    class TypeSeeder < ::BasicData::TypeSeeder
      def type_names
        %i[task milestone phase feature epic user_story bug]
      end

      def type_table
        { # position is_default color_id is_in_roadmap is_milestone
          task:       [1, true, I18n.t(:default_color_blue),        true,  false, :default_type_task],
          milestone:  [2, true, I18n.t(:default_color_green_light), false, true,  :default_type_milestone],
          phase:      [3, true, I18n.t(:default_color_blue_light),  false, false, :default_type_phase],
          feature:    [4, true, 'indigo-5',                 true,  false, :default_type_feature],
          epic:       [5, true, 'violet-5',                 true,  false, :default_type_epic],
          user_story: [6, true, 'orange-5',                 true,  false, :default_type_user_story],
          bug:        [7, true, 'red-7',                    true,  false, :default_type_bug]
        }
      end
    end
  end
end
