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

require_dependency 'app/models/queries/work_packages/filter/assigned_to_filter'
require_dependency 'app/models/queries/work_packages/filter/author_filter'
require_dependency 'app/models/queries/work_packages/filter/category_filter'
require_dependency 'app/models/queries/work_packages/filter/created_at_filter'
require_dependency 'app/models/queries/work_packages/filter/custom_field_filter'
require_dependency 'app/models/queries/work_packages/filter/done_ratio_filter'
require_dependency 'app/models/queries/work_packages/filter/due_date_filter'
require_dependency 'app/models/queries/work_packages/filter/estimated_hours_filter'
require_dependency 'app/models/queries/work_packages/filter/group_filter'
require_dependency 'app/models/queries/work_packages/filter/priority_filter'
require_dependency 'app/models/queries/work_packages/filter/project_filter'
require_dependency 'app/models/queries/work_packages/filter/responsible_filter'
require_dependency 'app/models/queries/work_packages/filter/role_filter'
require_dependency 'app/models/queries/work_packages/filter/start_date_filter'
require_dependency 'app/models/queries/work_packages/filter/status_filter'
require_dependency 'app/models/queries/work_packages/filter/subject_filter'
require_dependency 'app/models/queries/work_packages/filter/subproject_filter'
require_dependency 'app/models/queries/work_packages/filter/type_filter'
require_dependency 'app/models/queries/work_packages/filter/updated_at_filter'
require_dependency 'app/models/queries/work_packages/filter/version_filter'
require_dependency 'app/models/queries/work_packages/filter/watcher_filter'

module Queries::WorkPackages
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::AssignedToFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::AuthorFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::CategoryFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::CreatedAtFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::CustomFieldFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::DoneRatioFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::DueDateFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::EstimatedHoursFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::GroupFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::PriorityFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::ProjectFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::ResponsibleFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::RoleFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::StartDateFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::StatusFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::SubjectFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::SubprojectFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::TypeFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::UpdatedAtFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::VersionFilter
  Queries::Register.filter Query, ::Queries::WorkPackages::Filter::WatcherFilter
end
