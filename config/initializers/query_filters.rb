#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

# prevent loading problems
require 'principal'
require 'user'
require 'group'

Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::AssignedToFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::AuthorFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::CategoryFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::CreatedAtFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::CustomFieldFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::DoneRatioFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::DueDateFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::EstimatedHoursFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::GroupFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::PriorityFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::ProjectFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::ResponsibleFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::RoleFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::StartDateFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::StatusFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::SubjectFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::SubprojectFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::TypeFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::UpdatedAtFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::VersionFilter
Queries::FilterRegister.register Query, Queries::WorkPackages::Filter::WatcherFilter
