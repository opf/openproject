#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

class RbQueriesController < RbApplicationController
  include WorkPackagesFilterHelper

  def show
    filters = []
    if @sprint_id
      filters.push(filter_object('status_id', '*'))
      filters.push(filter_object('fixed_version_id', '=', [@sprint_id]))
    # Note: We need a filter for backlogs_work_package_type but currently it's not possible for plugins to introduce new filter types
    else
      filters.push(filter_object('status_id', 'o'))
      filters.push(filter_object('fixed_version_id', '!*', [@sprint_id]))
      # Same as above
    end

    query = {
      f: filters,
      c: ['type', 'status', 'priority', 'subject', 'assigned_to', 'updated_at', 'position'],
      t: 'position:desc'
    }

    redirect_to project_work_packages_with_query_path(@project, query)
  end
end
