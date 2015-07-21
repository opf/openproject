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

if PlanningElementTypeColor.any?
  puts '***** Skipping colors as there are already some configured'
else
  PlanningElementTypeColor.transaction do
    PlanningElementTypeColor.create(name: 'Blue',
                                    hexcode: '#3493B3')

    PlanningElementTypeColor.create(name: 'Blue-dark',
                                    hexcode: '#06799F')

    PlanningElementTypeColor.create(name: 'Green-light',
                                    hexcode: '#35C53F')

    PlanningElementTypeColor.create(name: 'Green-dark',
                                    hexcode: '#339933')

    PlanningElementTypeColor.create(name: 'Yellow',
                                    hexcode: '#FFFF00')

    PlanningElementTypeColor.create(name: 'Orange',
                                    hexcode: '#FFCC00')

    PlanningElementTypeColor.create(name: 'Red',
                                    hexcode: '#CC3333')

    PlanningElementTypeColor.create(name: 'Magenta',
                                    hexcode: '#E20074')

    PlanningElementTypeColor.create(name: 'White',
                                    hexcode: '#FFFFFF')

    PlanningElementTypeColor.create(name: 'Grey-light',
                                    hexcode: '#F8F8F8')

    PlanningElementTypeColor.create(name: 'Grey-medium',
                                    hexcode: '#EAEAEA')

    PlanningElementTypeColor.create(name: 'Grey-dark',
                                    hexcode: '#878787')

    PlanningElementTypeColor.create(name: 'Grey-dark',
                                    hexcode: '#000000')
  end
end
