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

module LlmConnections
  module SemanticIndexes
    class BoxComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      POLL_INTERVAL_MS = 2000

      options :semantic_indexes

      def rows
        active, others = semantic_indexes.partition { it.id == active_semantic_index_id }
        active + others
      end

      def wrapper_data_attrs
        data = { test_selector: "llm-semantic-index--box" }
        return { data: } unless semantic_indexes.any?(&:indexing?)

        data.merge!(
          controller: "poll-for-changes",
          poll_for_changes_url_value: status_semantic_indexes_path,
          poll_for_changes_interval_value: POLL_INTERVAL_MS
        )
        { data: }
      end

      private

      def active_semantic_index_id
        @active_semantic_index_id ||= SemanticIndex.active_id
      end
    end
  end
end
