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

# Matches workflows whose transitions reference the given statuses as either the
# old or the new status.
class Queries::Workflows::Filters::StatusFilter < Queries::Filters::Base
  self.model = Workflow

  def type
    :list
  end

  def self.key
    :status_id
  end

  def human_name
    ::Status.model_name.human
  end

  def allowed_values
    @allowed_values ||= ::Status.order(:position).pluck(:id, :name).map { |id, name| [name, id.to_s] }
  end

  def value_objects
    ::Status.where(id: values)
  end

  def where
    [transition_exists_sql, { ids: values.map(&:to_i) }]
  end

  private

  def transition_exists_sql
    <<~SQL.squish
      EXISTS (
        SELECT 1
        FROM workflows_status_transitions transitions
        WHERE transitions.workflow_id = #{self.class.model.table_name}.id
          AND (transitions.old_status_id IN (:ids) OR transitions.new_status_id IN (:ids))
      )
    SQL
  end
end
