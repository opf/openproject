#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

class Queries::WorkPackages::Selects::TypeaheadSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  def self.instances(_context = nil)
    new :typeahead,
        displayable: false,
        # This is an ugly hack. When using the typeahead order, the work packages should always be ordered
        # by their updated_at. But when asc is specified for typeahead, the updated_at property is to be used
        # in desc order.
        sortable: ->(table_name = WorkPackage.table_name) { "#{table_name}.updated_at DESC, #{table_name}.updated_at" }
  end
end
