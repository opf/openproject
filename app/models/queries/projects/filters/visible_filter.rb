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

# Returns projects visible for a user.
# This filter is only useful for admins which want to scope down the list of all the projects to those
# visible by a user. For a non admin user, the vanilla project query is already limited to the visible projects.
class Queries::Projects::Filters::VisibleFilter < Queries::Projects::Filters::Base
  validate :validate_only_single_value

  def allowed_values
    # Disregard the need for a proper name (as it is no longer actually displayed)
    # in favor of speed.
    @allowed_values ||= User.pluck(:id, :id)
  end

  def apply_to(_query_scope)
    super.where(id: Project.visible(User.find(values.first)))
  end

  def where
    # Handled by scope
    nil
  end

  def type
    :list
  end

  def available_operators
    [::Queries::Operators::Equals]
  end

  private

  def validate_only_single_value
    errors.add(:values, :invalid) if values.length != 1
  end
end
