#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module Queries::Projects
  filters = ::Queries::Projects::Filters
  orders = ::Queries::Projects::Orders
  query = ::Queries::Projects::ProjectQuery

  ::Queries::Register.register do
    filter query, filters::AncestorFilter
    filter query, filters::TypeFilter
    filter query, filters::ActiveFilter
    filter query, filters::TemplatedFilter
    filter query, filters::PublicFilter
    filter query, filters::NameAndIdentifierFilter
    filter query, filters::CustomFieldFilter
    filter query, filters::CreatedAtFilter
    filter query, filters::LatestActivityAtFilter
    filter query, filters::PrincipalFilter
    filter query, filters::ParentFilter
    filter query, filters::IdFilter
    filter query, filters::ProjectStatusFilter
    filter query, filters::UserActionFilter
    filter query, filters::VisibleFilter

    order query, orders::DefaultOrder
    order query, orders::LatestActivityAtOrder
    order query, orders::RequiredDiskSpaceOrder
    order query, orders::CustomFieldOrder
    order query, orders::ProjectStatusOrder
    order query, orders::NameOrder
  end
end
