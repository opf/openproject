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

class Queries::Projects::Orders::RequiredDiskSpaceOrder < Queries::Orders::Base
  self.model = Project

  def self.key
    :required_disk_space
  end

  private

  def joins
    <<~SQL.squish
      LEFT JOIN (#{Project.wiki_storage_sql}) wiki_for_sort ON projects.id = wiki_for_sort.project_id
      LEFT JOIN (#{Project.work_package_storage_sql}) wp_for_sort ON projects.id = wp_for_sort.project_id
      LEFT JOIN #{Repository.table_name} repos_for_sort ON repos_for_sort.project_id = projects.id
    SQL
  end

  def order(scope)
    with_raise_on_invalid do
      attribute = Arel.sql(<<~SQL.squish)
        (
          COALESCE(wiki_for_sort.filesize, 0) +
          COALESCE(wp_for_sort.filesize, 0) +
          COALESCE(repos_for_sort.required_storage_bytes, 0)
        )
      SQL
      scope.order(attribute.send(direction))
    end
  end
end
