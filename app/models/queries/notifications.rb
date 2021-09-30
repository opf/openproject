#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module Queries::Notifications
  [Queries::Notifications::Filters::ReadIanFilter,
   Queries::Notifications::Filters::IdFilter,
   Queries::Notifications::Filters::ProjectFilter,
   Queries::Notifications::Filters::ReasonFilter,
   Queries::Notifications::Filters::ResourceIdFilter,
   Queries::Notifications::Filters::ResourceTypeFilter].each do |filter|
    Queries::Register.filter Queries::Notifications::NotificationQuery,
                             filter
  end

  [Queries::Notifications::Orders::DefaultOrder,
   Queries::Notifications::Orders::ReasonOrder,
   Queries::Notifications::Orders::ProjectOrder,
   Queries::Notifications::Orders::ReadIanOrder].each do |order|
    Queries::Register.order Queries::Notifications::NotificationQuery,
                            order
  end

  [Queries::Notifications::GroupBys::GroupByReason,
   Queries::Notifications::GroupBys::GroupByProject].each do |group|
    Queries::Register.group_by Queries::Notifications::NotificationQuery,
                               group
  end
end
