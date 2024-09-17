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

class CostQuery::Filter::UserId < Report::Filter::Base
  def self.label
    WorkPackage.human_attribute_name(:user)
  end

  def self.me_value
    "me".freeze
  end

  def transformed_values
    # Map the special 'me' value
    super
        .filter_map { |val| replace_me_value(val) }
  end

  def replace_me_value(value)
    return value unless value == CostQuery::Filter::UserId.me_value

    if User.current.logged?
      User.current.id
    end
  end

  def self.available_values(*)
    # All users which are members in projects the user can see.
    # Excludes the anonymous user
    users = User.joins(members: :project)
                .merge(Project.visible)
                .human
                .select(User::USER_FORMATS_STRUCTURE[Setting.user_format].map(&:to_s) << :id)
                .distinct

    values = users.map { |u| [u.name, u.id] }
    values.unshift [::I18n.t(:label_me), me_value] if User.current.logged?
    values
  end
end
