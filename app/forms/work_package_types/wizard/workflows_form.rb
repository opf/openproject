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

module WorkPackageTypes
  module Wizard
    # Independent-mode workflows: optionally seed the sub-type's workflows by
    # copying them from another type, otherwise start from an empty workflow.
    class WorkflowsForm < ApplicationForm
      form do |workflows_form|
        workflows_form.select_list(
          name: :copy_workflow_from,
          input_width: :medium,
          label: I18n.t(:label_copy_workflow_from),
          caption: I18n.t("types.creation_wizard.workflows.copy_caption"),
          include_blank: true
        ) do |source_types|
          copyable_types.each do |type|
            source_types.option(value: type.id, label: type.name)
          end
        end
      end

      private

      def copyable_types
        Type.where.not(id: model.id).order(:position)
      end
    end
  end
end
