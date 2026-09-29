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

module Workflows
  class CopySourceForm < ApplicationForm
    def initialize(candidates:, selected:, type_workflow_id: nil)
      super()

      @candidates = candidates
      @selected = selected
      @type_workflow_id = type_workflow_id
    end

    form do |source_form|
      source_form.autocompleter(
        name: :copy_from_id,
        label: I18n.t("workflows.start.copy.panel_label"),
        visually_hide_label: true,
        required: true,
        autocomplete_options: {
          placeholder: I18n.t("workflows.form.copy_from.placeholder"),
          decorated: true,
          multiple: false,
          focusDirectly: false,
          append_to: "##{::Workflows::FormComponent::DIALOG_ID}",
          data: { test_selector: "workflow-copy-source" }
        }
      ) do |list|
        candidates.each do |candidate|
          list.option(value: candidate.id, label: label_for(candidate), selected: candidate.id == selected)
        end
      end
    end

    private

    attr_reader :candidates, :selected, :type_workflow_id

    def label_for(candidate)
      return candidate.name unless candidate.id == type_workflow_id

      "#{candidate.name} #{I18n.t('admin.workflows.workflow_selector.same_as_type')}"
    end
  end
end
