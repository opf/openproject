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
  class ColorSchemeSeeder < Seeder
    def seed_data!
      Color.transaction do
        data.each do |attributes|
          Color.create(attributes)
        end
      end
    end

    def applicable?
      Color.where(name: %w(grape-0 grape-1)).empty?
    end

    def not_applicable_message
      'Skipping flat colors as there are already some configured'
    end

    ##
    # Pallette by open-color
    # https://yeun.github.io/open-color/
    def data
      [
        { name: 'gray-0', hexcode: '#f8f9fa' },
        { name: 'gray-1', hexcode: '#f1f3f5' },
        { name: 'gray-2', hexcode: '#e9ecef' },
        { name: 'gray-3', hexcode: '#dee2e6' },
        { name: 'gray-4', hexcode: '#ced4da' },
        { name: 'gray-5', hexcode: '#adb5bd' },
        { name: 'gray-6', hexcode: '#868e96' },
        { name: 'gray-7', hexcode: '#495057' },
        { name: 'gray-8', hexcode: '#343a40' },
        { name: 'gray-9', hexcode: '#212529' },
        { name: 'red-0', hexcode: '#fff5f5' },
        { name: 'red-1', hexcode: '#ffe3e3' },
        { name: 'red-2', hexcode: '#ffc9c9' },
        { name: 'red-3', hexcode: '#ffa8a8' },
        { name: 'red-4', hexcode: '#ff8787' },
        { name: 'red-5', hexcode: '#ff6b6b' },
        { name: 'red-6', hexcode: '#fa5252' },
        { name: 'red-7', hexcode: '#f03e3e' },
        { name: 'red-8', hexcode: '#e03131' },
        { name: 'red-9', hexcode: '#c92a2a' },
        { name: 'pink-0', hexcode: '#fff0f6' },
        { name: 'pink-1', hexcode: '#ffdeeb' },
        { name: 'pink-2', hexcode: '#fcc2d7' },
        { name: 'pink-3', hexcode: '#faa2c1' },
        { name: 'pink-4', hexcode: '#f783ac' },
        { name: 'pink-5', hexcode: '#f06595' },
        { name: 'pink-6', hexcode: '#e64980' },
        { name: 'pink-7', hexcode: '#d6336c' },
        { name: 'pink-8', hexcode: '#c2255c' },
        { name: 'pink-9', hexcode: '#a61e4d' },
        { name: 'grape-0', hexcode: '#f8f0fc' },
        { name: 'grape-1', hexcode: '#f3d9fa' },
        { name: 'grape-2', hexcode: '#eebefa' },
        { name: 'grape-3', hexcode: '#e599f7' },
        { name: 'grape-4', hexcode: '#da77f2' },
        { name: 'grape-5', hexcode: '#cc5de8' },
        { name: 'grape-6', hexcode: '#be4bdb' },
        { name: 'grape-7', hexcode: '#ae3ec9' },
        { name: 'grape-8', hexcode: '#9c36b5' },
        { name: 'grape-9', hexcode: '#862e9c' },
        { name: 'violet-0', hexcode: '#f3f0ff' },
        { name: 'violet-1', hexcode: '#e5dbff' },
        { name: 'violet-2', hexcode: '#d0bfff' },
        { name: 'violet-3', hexcode: '#b197fc' },
        { name: 'violet-4', hexcode: '#9775fa' },
        { name: 'violet-5', hexcode: '#845ef7' },
        { name: 'violet-6', hexcode: '#7950f2' },
        { name: 'violet-7', hexcode: '#7048e8' },
        { name: 'violet-8', hexcode: '#6741d9' },
        { name: 'violet-9', hexcode: '#5f3dc4' },
        { name: 'indigo-0', hexcode: '#edf2ff' },
        { name: 'indigo-1', hexcode: '#dbe4ff' },
        { name: 'indigo-2', hexcode: '#bac8ff' },
        { name: 'indigo-3', hexcode: '#91a7ff' },
        { name: 'indigo-4', hexcode: '#748ffc' },
        { name: 'indigo-5', hexcode: '#5c7cfa' },
        { name: 'indigo-6', hexcode: '#4c6ef5' },
        { name: 'indigo-7', hexcode: '#4263eb' },
        { name: 'indigo-8', hexcode: '#3b5bdb' },
        { name: 'indigo-9', hexcode: '#364fc7' },
        { name: 'blue-0', hexcode: '#e7f5ff' },
        { name: 'blue-1', hexcode: '#d0ebff' },
        { name: 'blue-2', hexcode: '#a5d8ff' },
        { name: 'blue-3', hexcode: '#74c0fc' },
        { name: 'blue-4', hexcode: '#4dabf7' },
        { name: 'blue-5', hexcode: '#339af0' },
        { name: 'blue-6', hexcode: '#228be6' },
        { name: 'blue-7', hexcode: '#1c7ed6' },
        { name: 'blue-8', hexcode: '#1971c2' },
        { name: 'blue-9', hexcode: '#1864ab' },
        { name: 'cyan-0', hexcode: '#e3fafc' },
        { name: 'cyan-1', hexcode: '#c5f6fa' },
        { name: 'cyan-2', hexcode: '#99e9f2' },
        { name: 'cyan-3', hexcode: '#66d9e8' },
        { name: 'cyan-4', hexcode: '#3bc9db' },
        { name: 'cyan-5', hexcode: '#22b8cf' },
        { name: 'cyan-6', hexcode: '#15aabf' },
        { name: 'cyan-7', hexcode: '#1098ad' },
        { name: 'cyan-8', hexcode: '#0c8599' },
        { name: 'cyan-9', hexcode: '#0b7285' },
        { name: 'teal-0', hexcode: '#e6fcf5' },
        { name: 'teal-1', hexcode: '#c3fae8' },
        { name: 'teal-2', hexcode: '#96f2d7' },
        { name: 'teal-3', hexcode: '#63e6be' },
        { name: 'teal-4', hexcode: '#38d9a9' },
        { name: 'teal-5', hexcode: '#20c997' },
        { name: 'teal-6', hexcode: '#12b886' },
        { name: 'teal-7', hexcode: '#0ca678' },
        { name: 'teal-8', hexcode: '#099268' },
        { name: 'teal-9', hexcode: '#087f5b' },
        { name: 'green-0', hexcode: '#ebfbee' },
        { name: 'green-1', hexcode: '#d3f9d8' },
        { name: 'green-2', hexcode: '#b2f2bb' },
        { name: 'green-3', hexcode: '#8ce99a' },
        { name: 'green-4', hexcode: '#69db7c' },
        { name: 'green-5', hexcode: '#51cf66' },
        { name: 'green-6', hexcode: '#40c057' },
        { name: 'green-7', hexcode: '#37b24d' },
        { name: 'green-8', hexcode: '#2f9e44' },
        { name: 'green-9', hexcode: '#2b8a3e' },
        { name: 'lime-0', hexcode: '#f4fce3' },
        { name: 'lime-1', hexcode: '#e9fac8' },
        { name: 'lime-2', hexcode: '#d8f5a2' },
        { name: 'lime-3', hexcode: '#c0eb75' },
        { name: 'lime-4', hexcode: '#a9e34b' },
        { name: 'lime-5', hexcode: '#94d82d' },
        { name: 'lime-6', hexcode: '#82c91e' },
        { name: 'lime-7', hexcode: '#74b816' },
        { name: 'lime-8', hexcode: '#66a80f' },
        { name: 'lime-9', hexcode: '#5c940d' },
        { name: 'yellow-0', hexcode: '#fff9db' },
        { name: 'yellow-1', hexcode: '#fff3bf' },
        { name: 'yellow-2', hexcode: '#ffec99' },
        { name: 'yellow-3', hexcode: '#ffe066' },
        { name: 'yellow-4', hexcode: '#ffd43b' },
        { name: 'yellow-5', hexcode: '#fcc419' },
        { name: 'yellow-6', hexcode: '#fab005' },
        { name: 'yellow-7', hexcode: '#f59f00' },
        { name: 'yellow-8', hexcode: '#f08c00' },
        { name: 'yellow-9', hexcode: '#e67700' },
        { name: 'orange-0', hexcode: '#fff4e6' },
        { name: 'orange-1', hexcode: '#ffe8cc' },
        { name: 'orange-2', hexcode: '#ffd8a8' },
        { name: 'orange-3', hexcode: '#ffc078' },
        { name: 'orange-4', hexcode: '#ffa94d' },
        { name: 'orange-5', hexcode: '#ff922b' },
        { name: 'orange-6', hexcode: '#fd7e14' },
        { name: 'orange-7', hexcode: '#f76707' },
        { name: 'orange-8', hexcode: '#e8590c' },
        { name: 'orange-9', hexcode: '#d9480f' }
      ]
    end
  end
end
