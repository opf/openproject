#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api::V2::Concerns::MultipleProjects
  def load_multiple_projects(ids, identifiers)
    @projects = []
    @projects |= Project.where(id: ids) unless ids.empty?
    @projects |= Project.where(identifier: identifiers) unless identifiers.empty?
  end

  def projects_contain_certain_ids_and_identifiers(ids, identifiers)
    (@projects.map(&:id) & ids).size == ids.size &&
      (@projects.map(&:identifier) & identifiers).size == identifiers.size
  end

  def filter_authorized_projects
    # authorize
    # Ignoring projects, where user has no view_work_packages permission.
    permission = params[:controller].sub api_version, ''
    @projects = @projects.select { |project|
      User.current.allowed_to?({ controller: permission,
                                 action:     params[:action] },
                               project)
    }
  end
end
