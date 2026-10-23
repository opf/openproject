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

module AI
  module TextTransforms
    class ResultPaneComponent
      # Demo glue (AI-126 demo branch, until AI-175 adds its component part): the forms the
      # footer buttons submit and the state element the pane controller polls with.
      class Footer < Section
        private

        def state_data
          {
            controller: "ai-text-transform-pane-run",
            ai_text_transform_pane_run_state_value: state,
            ai_text_transform_pane_run_run_value: pane.uuid,
            ai_text_transform_pane_run_seq_value: pane.last_seq,
            ai_text_transform_pane_run_request_id_value: pane.request_id,
            ai_text_transform_pane_run_poll_url_value: helpers.ai_text_transform_pane_path(pane.uuid, form_params),
            ai_text_transform_pane_run_editor_gone_value: label(:editor_gone),
            ai_text_transform_pane_run_selection_gone_value: label(:selection_gone)
          }
        end

        def form_params
          { request_id: pane.request_id, scope: pane.scope }.merge(pane.context_ids).compact
        end

        def retryable?
          pane.run && %w[failed stopped].include?(state)
        end

        def form(id:, url:, method:, fields: form_params)
          helpers.form_with(url:, method:, id:, data: { turbo_stream: true }) do
            safe_join(fields.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) })
          end
        end
      end
    end
  end
end
