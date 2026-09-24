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
  class WorkflowPanelComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(variant:, candidates:, name:, selected: nil, back_url: nil)
      super()

      @variant = variant
      @candidates = candidates
      @name = name
      @selected = selected
      @back_url = back_url
    end

    private

    attr_reader :variant, :candidates, :name, :back_url

    def prefix = "#{I18n.t('admin.workflows.workflow_selector.prefix')}:"

    def same_as_type_text = I18n.t("admin.workflows.workflow_selector.same_as_type")

    def same_as_type?
      return false if variant.is_default_variant?

      variant.workflow_id == variant.type.default_variant.workflow_id
    end

    def selected = @selected || variant.workflow_id

    def change_path(candidate)
      url_helpers.change_type_workflow_path(
        **variant.path_args.merge(workflow_id: candidate.id, back_url:).compact
      )
    end
  end
end
