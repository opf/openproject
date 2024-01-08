#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Queries::WorkPackages::Filter::SubprojectFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    @allowed_values ||= visible_subproject_array.map { |id, name| [name, id.to_s] }
  end

  def default_operator
    ::Queries::Operators::All
  end

  def available?
    project &&
      !project.leaf? &&
      visible_subprojects.any?
  end

  def type
    :list_optional
  end

  def human_name
    I18n.t('query_fields.subproject_id')
  end

  def self.key
    :subproject_id
  end

  def ar_object_filter?
    true
  end

  def value_objects
    available_subprojects = visible_subprojects.index_by(&:id)

    values
      .filter_map { |subproject_id| available_subprojects[subproject_id.to_i] }
  end

  def where
    "#{Project.table_name}.id IN (%s)" % ids_for_where.join(',')
  end

  protected

  def ids_for_where
    [project.id] + ids_for_where_subproject
  end

  def ids_for_where_subproject
    case operator
    when ::Queries::Operators::Equals.symbol
      # include the selected subprojects
      value_ints
    when ::Queries::Operators::All.symbol
      visible_subproject_ids
    when ::Queries::Operators::NotEquals.symbol
      visible_subproject_ids - value_ints
    else # None
      []
    end
  end

  def visible_subproject_array
    visible_subprojects.pluck(:id, :name)
  end

  def visible_subprojects
    # This can be accessed even when `available?` is false
    @visible_subprojects ||= if project.nil?
                               []
                             else
                               project.descendants.visible
                             end
  end

  def visible_subproject_ids
    visible_subproject_array.map(&:first)
  end

  def value_ints
    values.map(&:to_i)
  end
end
