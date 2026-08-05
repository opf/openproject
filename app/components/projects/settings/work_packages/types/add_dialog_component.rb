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

module Projects
  module Settings
    module WorkPackages
      module Types
        # Picks the type or variant a project should activate. Only families
        # with no active member are offered; swapping the active member of a
        # family is FND-188's switch dialog.
        class AddDialogComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers
          include OpTurbo::Streamable

          DIALOG_ID = "project-types-add-dialog"

          def initialize(project:)
            super()

            @project = project
          end

          private

          attr_reader :project

          def create_path
            project_settings_work_packages_types_path(project)
          end

          def addable_types
            @addable_types ||= ::Type.global.where.not(id: active_root_ids).in_family_order
          end

          # A family is addable as a whole, so any active member rules out all of it.
          def active_root_ids
            @active_root_ids ||= project.types.pluck(:parent_id, :id).map { |parent_id, id| parent_id || id }
          end
        end
      end
    end
  end
end
