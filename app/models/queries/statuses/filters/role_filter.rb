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

class Queries::Statuses::Filters::RoleFilter < Queries::Statuses::Filters::WorkflowFilter
  # Role eager-loads its permissions, so plucking here would yield one entry per
  # permission rather than per role.
  def allowed_values
    eligible_roles.map { |role| [role.name, role.id.to_s] }
  end

  def where
    transition_where("role_id", values.map(&:to_i))
  end

  def human_name
    Role.model_name.human
  end

  def eligible_roles
    Workflow.eligible_roles.order(Arel.sql("builtin, position"))
  end
end
