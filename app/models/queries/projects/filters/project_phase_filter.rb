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

class Queries::Projects::Filters::ProjectPhaseFilter < Queries::Projects::Filters::Base
  include Queries::Projects::Filters::DynamicallyFromProjectPhase
  include Queries::Projects::Filters::FilterOnProjectPhase

  class << self
    def key
      /\Aproject_phase_(?<id>\d+)\z/
    end

    private

    def create_from_phase(phase, context)
      create!(name: "project_phase_#{phase.id}", context:)
    end
  end

  def human_name
    I18n.t("project.filters.project_phase", phase: project_phase_definition.name)
  end

  private

  def on_date
    phase_where_on(parsed_start)
  end

  def on_today
    phase_where_on(today)
  end

  def between_date
    phase_where_between(parsed_start, parsed_end)
  end

  def this_week
    phase_overlaps_this_week
  end

  def none
    phase_none
  end

  def project_phase_scope_limit(scope)
    super
      .where(definition_id: project_phase_definition.id)
  end
end
