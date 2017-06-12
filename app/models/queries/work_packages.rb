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

module Queries::WorkPackages
  filters_module = Queries::WorkPackages::Filter
  register = Queries::Register

  register.filter Query, filters_module::AssignedToFilter
  register.filter Query, filters_module::AuthorFilter
  register.filter Query, filters_module::CategoryFilter
  register.filter Query, filters_module::CreatedAtFilter
  register.filter Query, filters_module::CustomFieldFilter
  register.filter Query, filters_module::DoneRatioFilter
  register.filter Query, filters_module::DueDateFilter
  register.filter Query, filters_module::EstimatedHoursFilter
  register.filter Query, filters_module::GroupFilter
  register.filter Query, filters_module::IdFilter
  register.filter Query, filters_module::PriorityFilter
  register.filter Query, filters_module::ProjectFilter
  register.filter Query, filters_module::ResponsibleFilter
  register.filter Query, filters_module::RoleFilter
  register.filter Query, filters_module::StartDateFilter
  register.filter Query, filters_module::StatusFilter
  register.filter Query, filters_module::SubjectFilter
  register.filter Query, filters_module::SubprojectFilter
  register.filter Query, filters_module::TypeFilter
  register.filter Query, filters_module::UpdatedAtFilter
  register.filter Query, filters_module::VersionFilter
  register.filter Query, filters_module::WatcherFilter

  columns_module = Queries::WorkPackages::Columns

  register.column Query, columns_module::PropertyColumn
  register.column Query, columns_module::CustomFieldColumn
  register.column Query, columns_module::RelationToTypeColumn
  register.column Query, columns_module::RelationOfTypeColumn
end
