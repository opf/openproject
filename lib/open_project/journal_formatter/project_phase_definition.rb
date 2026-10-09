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

class OpenProject::JournalFormatter::ProjectPhaseDefinition < JournalFormatter::NamedAssociation
  private

  def associated_object_name(object)
    if object.nil?
      I18n.t(:"activity.project_phase.deleted_project_phase")
    elsif phase_active?(object)
      super
    else
      "#{super} (#{I18n.t(:label_inactive)})"
    end
  end

  def phase_active?(definition)
    @journal
      .journable
      .project
      .phases
      .detect { |phase| phase.definition_id == definition.id }
      &.active
  end
end
