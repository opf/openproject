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
# See docs/COPYRIGHT.rdoc for more details.
#++

class Queries::Principals::Filters::MemberFilter < Queries::Principals::Filters::PrincipalFilter
  def allowed_values
    Project.active.all.map do |project|
      [project.name, project.id]
    end
  end

  def type
    :list_optional
  end

  def self.key
    :member
  end

  def scope
    default_scope = Principal.includes(:members)

    case operator
    when '='
      default_scope.where(members: { project_id: values })
    when '!'
      default_scope.where.not(members: { project_id: values })
    when '*'
      default_scope.where.not(members: { project_id: nil })
    when '!*'
      default_scope.where.not(id: Member.select(:user_id).uniq)
    end
  end
end
