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

module Queries::WorkPackages
  ::Queries::Register.register(Query) do
    filter Filter::AssignedToFilter
    filter Filter::AssigneeOrGroupFilter
    filter Filter::AttachmentContentFilter
    filter Filter::AttachmentFileNameFilter
    filter Filter::AuthorFilter
    filter Filter::CategoryFilter
    filter Filter::CreatedAtFilter
    filter Filter::CustomFieldFilter
    filter Filter::DoneRatioFilter
    filter Filter::DueDateFilter
    filter Filter::EstimatedHoursFilter
    filter Filter::GroupFilter
    filter Filter::IdFilter
    filter Filter::PriorityFilter
    filter Filter::ProjectFilter
    filter Filter::ResponsibleFilter
    filter Filter::RoleFilter
    filter Filter::SharedWithUserFilter
    filter Filter::SharedWithMeFilter
    filter Filter::StartDateFilter
    filter Filter::StatusFilter
    filter Filter::SubjectFilter
    filter Filter::SubprojectFilter
    filter Filter::OnlySubprojectFilter
    filter Filter::TypeFilter
    filter Filter::UpdatedAtFilter
    filter Filter::VersionFilter
    filter Filter::WatcherFilter
    filter Filter::DatesIntervalFilter
    filter Filter::ParentFilter
    filter Filter::PrecedesFilter
    filter Filter::FollowsFilter
    filter Filter::RelatesFilter
    filter Filter::DuplicatesFilter
    filter Filter::DuplicatedFilter
    filter Filter::BlocksFilter
    filter Filter::BlockedFilter
    filter Filter::PartofFilter
    filter Filter::IncludesFilter
    filter Filter::RequiresFilter
    filter Filter::RequiredFilter
    filter Filter::DescriptionFilter
    filter Filter::SearchFilter
    filter Filter::CommentFilter
    filter Filter::SubjectOrIdFilter
    filter Filter::ManualSortFilter
    filter Filter::RelatableFilter
    filter Filter::MilestoneFilter
    filter Filter::TypeaheadFilter
    filter Filter::DurationFilter
    exclude Filter::RelatableFilter

    select Selects::PropertySelect
    select Selects::CustomFieldSelect
    select Selects::RelationToTypeSelect
    select Selects::RelationOfTypeSelect
    select Selects::ManualSortingSelect
    select Selects::TypeaheadSelect
  end
end
