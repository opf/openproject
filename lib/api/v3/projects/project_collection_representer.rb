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

require 'roar/decorator'
require 'roar/json'
require 'roar/json/collection'
require 'roar/json/hal'

module API
  module V3
    module Projects
      class ProjectCollectionRepresenter < ::API::Decorators::UnpaginatedCollection
        element_decorator ::API::V3::Projects::ProjectRepresenter

        property :elements,
                   getter: ->(*) {
                     ids = represented.pluck(:id)


                     sql = <<SQL
SELECT array_to_json(array_agg(row_to_json(t))) 
                       FROM (
                        Select 
                          'Project' as _type,
                          projects.id, 
                          identifier, 
                          projects.name, 
                          description,
                          created_on as createdAt,
                          updated_on as updatedAt,
                          json_object_agg(links.name, json_build_object('href', href)) as _links
                        
                        FROM projects
						LEFT OUTER JOIN (SELECT name, href, id, present FROM
(SELECT
  blubs.name,
  CASE blubs.name
    WHEN 'work_packages' THEN '/api/v3/projects/' || projects.id || '/work_packages'
    WHEN 'createWorkPackage' THEN '/api/v3/projects/' || projects.id || '/work_packages/form'
    WHEN 'createWorkPackageImmediate' THEN '/api/v3/projects/' || projects.id || '/work_packages'
    WHEN 'categories' THEN '/api/v3/projects/' || projects.id || '/categories'
    WHEN 'versions' THEN '/api/v3/projects/' || projects.id || '/versions'
    WHEN 'types' THEN '/api/v3/projects/' || projects.id || '/types'
    ELSE ''
  END as href,
    CASE blubs.name
    WHEN 'work_packages' THEN view_work_packages.id IS NOT NULL
    WHEN 'createWorkPackage' THEN add_work_packages.id IS NOT NULL
    WHEN 'createWorkPackageImmediate' THEN add_work_packages.id IS NOT NULL
    WHEN 'versions' THEN manage_versions.id IS NOT NULL OR view_work_packages.id IS NOT NULL
    WHEN 'types' THEN manage_types.id IS NOT NULL OR view_work_packages.id IS NOT NULL
    ELSE true
  END AS present,
  projects.id
FROM
(SELECT 'work_packages' as name
UNION SELECT 'createWorkPackage'
UNION SELECT 'createWorkPackageImmediate'
UNION SELECT 'categories'
UNION SELECT 'versions'
UNION SELECT 'types'
) blubs
LEFT OUTER JOIN projects ON 1 = 1
LEFT OUTER JOIN (#{Project.allowed_to(User.current, :view_work_packages).select(:id).to_sql}) view_work_packages ON view_work_packages.id = projects.id
LEFT OUTER JOIN (#{Project.allowed_to(User.current, :view_work_packages).select(:id).to_sql}) add_work_packages ON add_work_packages.id = projects.id
LEFT OUTER JOIN (#{Project.allowed_to(User.current, :manage_versions).select(:id).to_sql}) manage_versions ON manage_versions.id = projects.id
LEFT OUTER JOIN (#{Project.allowed_to(User.current, :manage_types).select(:id).to_sql}) manage_types ON manage_types.id = projects.id
) blubs2) links ON links.id = projects.id  AND present = true
						   GROUP BY projects.id, projects.identifier, projects.name, description, created_on, updated_on
                       ) t
SQL

                     json = ActiveRecord::Base.connection
                       .select_one(sql)['array_to_json']

                     ::JSON::parse(json)
                   },
                   exec_context: :decorator,
                   embedded: true

        self.to_eager_load = ::API::V3::Projects::ProjectRepresenter.to_eager_load
        self.checked_permissions = ::API::V3::Projects::ProjectRepresenter.checked_permissions
      end
    end
  end
end
