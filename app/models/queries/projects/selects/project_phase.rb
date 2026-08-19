# frozen_string_literal: true

# -- copyright
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
# ++

class Queries::Projects::Selects::ProjectPhase < Queries::Selects::Base
  KEY = /\Aproject_phase_(\d+)\z/

  def self.key
    KEY
  end

  def self.all_available
    return [] unless available?

    Project::PhaseDefinition
      .pluck(:id)
      .map { |id| new(:"project_phase_#{id}") }
  end

  def caption
    project_phase_definition.name
  end

  def project_phase_definition
    return @project_phase_definition if defined?(@project_phase_definition)

    @project_phase_definition = Project::PhaseDefinition
                                    .find_by(id: attribute[KEY, 1])
  end

  def self.available?
    User.current.allowed_in_any_project?(:view_project_phases)
  end

  def available?
    project_phase_definition.present?
  end

  def visual_icon
    {
      icon: :"op-phase",
      classes: helpers.hl_inline_class("project_phase_definition", project_phase_definition)
    }
  end

  def action_menu_classes
    "leading-visual-icon-header"
  end

  private

  def helpers
    @helpers ||= Object.new.extend(ColorsHelper)
  end
end
