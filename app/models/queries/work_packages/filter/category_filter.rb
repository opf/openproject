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

class Queries::WorkPackages::Filter::CategoryFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    all_project_categories.map { |s| [s.name, s.id.to_s] }
  end

  def available?
    project&.categories&.exists?
  end

  def type
    :list_optional
  end

  def self.key
    :category_id
  end

  def value_objects
    available_categories = all_project_categories.index_by(&:id)

    values
      .filter_map { |category_id| available_categories[category_id.to_i] }
  end

  def ar_object_filter?
    true
  end

  private

  def all_project_categories
    @all_project_categories ||= project.categories
  end
end
