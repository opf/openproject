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

module AI
  module TextTransforms
    # Demo only (AI-126): the parts of the result pane the server streams separately (title, body
    # and footer), each rendered for the pane's current state.
    class ResultPaneSectionComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include ResultPaneHelpers

      def initialize(section:, pane:)
        super()
        @section = section
        @pane = pane
      end

      def wrapper_uniq_by
        section
      end

      private

      attr_reader :section, :pane

      delegate :state, to: :pane

      def context_label
        label(pane.selection? ? :context_selection : :context_description)
      end

      def output
        helpers.format_text(pane.text, object: pane.work_package)
      end

      def state_data
        target(:state).merge(
          state:,
          run: pane.uuid,
          seq: pane.last_seq,
          request_id: pane.request_id,
          poll_url: helpers.ai_text_transform_pane_path(pane.uuid, poll_params)
        )
      end

      def poll_params
        form_params.merge(pane.context_ids)
      end

      def form_params
        { request_id: pane.request_id, scope: pane.scope }.compact
      end

      def retry_params
        poll_params.merge(retry_of: pane.run&.uuid)
      end

      def form(id:, url:, method:, fields: form_params)
        helpers.form_with(url:, method:, id:, data: { turbo_stream: true }) do
          safe_join(fields.compact.map { |name, value| helpers.hidden_field_tag(name, value, id: nil) })
        end
      end
    end
  end
end
