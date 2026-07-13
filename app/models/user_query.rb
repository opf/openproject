# frozen_string_literal: true

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

class UserQuery < PersistedQuery
  scope :visible, ->(user = User.current) { where(principal: user) }

  def self.model
    User
  end

  def default_scope
    # Excludes the SystemUser, DeletedUser, AnonymousUser STI descendants of User.
    User.user.visible
  end

  register_query do
    filter Queries::Users::Filters::NameFilter
    filter Queries::Users::Filters::AnyNameAttributeFilter
    filter Queries::Users::Filters::GroupFilter
    filter Queries::Users::Filters::StatusFilter
    filter Queries::Users::Filters::LoginFilter
    filter Queries::Users::Filters::BlockedFilter
    filter Queries::Users::Filters::CustomFieldFilter

    order Queries::Users::Orders::DefaultOrder
    order Queries::Users::Orders::NameOrder
    order Queries::Users::Orders::GroupOrder
    order Queries::Users::Orders::CustomFieldOrder

    select Queries::Users::Selects::Default
    select Queries::Users::Selects::CustomField
  end
end
