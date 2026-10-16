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

# The dataset the user guide screenshots are taken from. Not part of `db:seed`:
# run it with `rake db:seed:only[UserGuideDataSeeder]`.
class UserGuideDataSeeder < CompositeSeeder
  def data_seeder_classes
    [
      # Seeds an empty database, as in the docs specs, or else looks up the roles the members refer to.
      ::Standard::BasicDataSeeder,
      UserGuideData::UsersSeeder,
      UserGuideData::ProjectSeeder,
      UserGuideData::ForumsSeeder
    ]
  end

  def namespace
    "UserGuideData"
  end
end
