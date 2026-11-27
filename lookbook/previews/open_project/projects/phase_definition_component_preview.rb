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

module OpenProject
  module Projects
    # @logical_path OpenProject/Projects
    class PhaseDefinitionComponentPreview < Lookbook::Preview
      # @param edit_link [boolean]
      # @param start_gate [boolean]
      # @param finish_gate [boolean]
      def phase(edit_link: false, start_gate: false, finish_gate: false)
        model = Project::PhaseDefinition.new(id: 1, name: "The first phase", start_gate:, finish_gate:)

        render_with_template(locals: { model:, edit_link: })
      end
    end
  end
end
