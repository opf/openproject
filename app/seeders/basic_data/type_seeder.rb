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
module BasicData
  class TypeSeeder < Seeder
    def seed_data!
      Type.transaction do
        data.each do |attributes|
          Type.create!(attributes)
        end
      end
    end

    def applicable
      Type.all.any?
    end

    def not_applicable_message
      'Skipping types - already exists/configured'
    end

    def data
      colors = PlanningElementTypeColor.all
      colors = colors.map { |c| { c.name =>  c.id } }.reduce({}, :merge)

      [
        { name: I18n.t(:default_type_task),       is_default: true,  color_id: colors[I18n.t(:default_color_grey)],        is_in_roadmap: true,  in_aggregation: false, is_milestone: false,  position: 1 },
        { name: I18n.t(:default_type_milestone),  is_default: false, color_id: colors[I18n.t(:default_color_green_light)], is_in_roadmap: false, in_aggregation: true, is_milestone: true,    position: 2 },
        { name: I18n.t(:default_type_phase),      is_default: false, color_id: colors[I18n.t(:default_color_blue_dark)],   is_in_roadmap: false, in_aggregation: true, is_milestone: false,   position: 3 },
        { name: I18n.t(:default_type_feature),    is_default: false, color_id: colors[I18n.t(:default_color_blue)],        is_in_roadmap: true,  in_aggregation: false, is_milestone: false,  position: 4 },
        { name: I18n.t(:default_type_epic),       is_default: false, color_id: colors[I18n.t(:default_color_orange)],      is_in_roadmap: true,  in_aggregation: true, is_milestone: false,   position: 5 },
        { name: I18n.t(:default_type_user_story), is_default: false, color_id: colors[I18n.t(:default_color_grey_dark)],   is_in_roadmap: true,  in_aggregation: false , is_milestone: false, position: 6 },
        { name: I18n.t(:default_type_bug),        is_default: false, color_id: colors[I18n.t(:default_color_red)],         is_in_roadmap: true,  in_aggregation: false , is_milestone: false, position: 7 }
      ]
    end
  end
end
