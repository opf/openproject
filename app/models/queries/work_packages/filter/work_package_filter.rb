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

class Queries::WorkPackages::Filter::WorkPackageFilter < ::Queries::Filters::Base
  include ::Queries::Filters::Serializable

  self.model = WorkPackage

  def human_name
    WorkPackage.human_attribute_name(name)
  end

  def project
    context.project
  end

  def includes
    nil
  end

  def scope
    # We only return the WorkPackage base scope for now as most of the filters
    # (this one's subclasses) currently do not follow the base filter approach of using the scope.
    # The intend is to have more and more wp filters use the scope method just like the
    # rest of the queries (e.g. project)
    WorkPackage.unscoped
  end
end
