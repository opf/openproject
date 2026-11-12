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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Here we are loading STI models explicitly using rails autoloader.
# It is relevant for environments where lazy loading is enabled (usually, development and testing).
# If an STI model has not been loaded it can lead to undesired behavior like:
# Fetching not loaded yet STI model (ServiceAccount) through its parent model(User)
# (e.g. User.find(service_account_id) raises ActiveRecord::NotFound.
Rails.application.config.to_prepare do
  # Load Enumeration descendants
  IssuePriority

  # Load Principal descendants
  User
  PlaceholderUser
  Group

  # Load User descendants
  SystemUser
  AnonymousUser
  Users::InexistentUser
  ServiceAccount
  DeletedUser
end
