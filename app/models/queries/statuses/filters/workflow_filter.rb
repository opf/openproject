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

# Statuses reach types and roles only through the transitions naming them. Both
# filters join through this one clause so that Rails collapses it to a single
# join and their conditions land on the same transition: picking Task and Member
# then matches the Task/Member workflow alone, rather than every status used by
# some Task workflow and, separately, by some Member workflow.
class Queries::Statuses::Filters::WorkflowFilter < Queries::Filters::Base
  TRANSITION_JOIN = <<~SQL.squish
    INNER JOIN workflows
    ON workflows.old_status_id = statuses.id OR workflows.new_status_id = statuses.id
  SQL

  self.model = Status

  def joins
    TRANSITION_JOIN
  end

  def type
    :list
  end

  def available_operators
    [::Queries::Operators::Equals]
  end

  private

  def transition_where(field, ids)
    operator_strategy.sql_for_field(ids, "workflows", field)
  end
end
