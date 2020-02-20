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
module BasicData
  class ColorSeeder < Seeder
    def seed_data!
      Color.transaction do
        data.each do |attributes|
          Color.create(attributes)
        end
      end
    end

    def applicable?
      Color.all.empty?
    end

    def not_applicable_message
      'Skipping colors as there are already some configured'
    end

    def data
      [
        { name: I18n.t(:default_color_blue_dark),   hexcode: '#175A8E' },
        { name: I18n.t(:default_color_blue),        hexcode: '#1A67A3' },
        { name: I18n.t(:default_color_blue_light),  hexcode: '#00B0F0' },
        { name: I18n.t(:default_color_green_light), hexcode: '#35C53F' },
        { name: I18n.t(:default_color_green_dark),  hexcode: '#339933' },
        { name: I18n.t(:default_color_yellow),      hexcode: '#FFFF00' },
        { name: I18n.t(:default_color_orange),      hexcode: '#FFCC00' },
        { name: I18n.t(:default_color_red),         hexcode: '#FF3300' },
        { name: I18n.t(:default_color_magenta),     hexcode: '#E20074' },
        { name: I18n.t(:default_color_white),       hexcode: '#FFFFFF' },
        { name: I18n.t(:default_color_grey_light),  hexcode: '#F8F8F8' },
        { name: I18n.t(:default_color_grey),        hexcode: '#EAEAEA' },
        { name: I18n.t(:default_color_grey_dark),   hexcode: '#878787' },
        { name: I18n.t(:default_color_black),       hexcode: '#000000' }
      ]
    end
  end
end
