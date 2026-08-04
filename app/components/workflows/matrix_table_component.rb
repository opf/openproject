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
  # One transition tab's matrix: a checkbox per (current status, new status) pair,
  # named status[old_status_id][new_status_id] so that MatrixUpdateService can rewrite
  # the tab from the submitted form.
  #
  # Renders the inputs only — the surrounding form belongs to whoever embeds the matrix.
  class MatrixTableComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(context:)
      super()

      @context = context
    end

    private

    attr_reader :context

    delegate :tab, :statuses, :workflows, :roles, :added_status_ids, :readonly?, to: :context

    def dom_id = "workflow_form_#{tab}"

    def heading
      case tab
      when "assignee" then t(:label_additional_workflow_transitions_for_assignee)
      when "author" then t(:label_additional_workflow_transitions_for_author)
      end
    end

    def caption
      t("workflows.form.matrix_caption_#{tab}", default: t("workflows.form.matrix_caption"))
    end

    def checkbox_label(old_status, new_status)
      t("workflows.form.matrix_checkbox_label", old_status: old_status.name, new_status: new_status.name)
    end

    def column_toggle_label(new_status)
      t("workflows.form.matrix_check_uncheck_all_in_col_label_html", new_status: new_status.name)
    end

    def row_toggle_label(old_status)
      t("workflows.form.matrix_check_uncheck_all_in_row_label_html", old_status: old_status.name)
    end

    def checked?(old_status, new_status)
      return false if indeterminate?(old_status, new_status)

      allowed_role_ids(old_status, new_status).any? || newly_added?(old_status, new_status)
    end

    # Only some of the selected roles allow this transition, so a plain checkbox cannot
    # represent it. A status that was only just added is exempt: no role can have it yet,
    # so it starts out checked for all of them instead.
    def indeterminate?(old_status, new_status)
      role_ids = allowed_role_ids(old_status, new_status)

      role_ids.any? && role_ids.size < roles.size && !newly_added?(old_status, new_status)
    end

    def allowed_role_ids(old_status, new_status)
      role_ids_by_transition.fetch([old_status.id, new_status.id], [])
    end

    def role_ids_by_transition
      @role_ids_by_transition ||= workflows
                                    .group_by { [it.old_status_id, it.new_status_id] }
                                    .transform_values { it.map(&:role_id).uniq }
    end

    def newly_added?(old_status, new_status)
      added_status_ids.include?(old_status.id) || added_status_ids.include?(new_status.id)
    end
  end
end
