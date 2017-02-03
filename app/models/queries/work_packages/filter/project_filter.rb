#-- encoding: UTF-8
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

class Queries::WorkPackages::Filter::ProjectFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    @allowed_values ||= begin
      project_values = []
      Project.project_tree(visible_projects) do |p, level|
        prefix = (level > 0 ? ('--' * level + ' ') : '')
        project_values << ["#{prefix}#{p.name}", p.id.to_s]
      end

      project_values
    end
  end

  def available?
    !project && visible_projects.exists?
  end

  def type
    :list
  end

  def order
    1
  end

  def self.key
    :project_id
  end

  def ar_object_filter?
    true
  end

  def value_objects
    value_ints = values.map(&:to_i)

    visible_projects.select { |p| value_ints.include?(p.id) }
  end

  private

  def visible_projects
    @visible_projects ||= Project.visible
  end
end
