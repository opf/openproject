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
    class PaneParamsContract < DryApplicationContract
      SCOPES = %w[document selection].freeze
      CONTEXT_KEYS = %i[work_package_id project_id type_id].freeze
      KEYS = %i[request_id scope work_package_id project_id type_id after state action_id input retry_of].freeze

      config.messages.namespace = :ai_text_transform_pane

      params do
        required(:request_id).filled(:string, :uuid_v4?)
        required(:scope).filled(:string, included_in?: SCOPES)
        optional(:work_package_id).maybe(:integer, gt?: 0)
        optional(:project_id).maybe(:integer, gt?: 0)
        optional(:type_id).maybe(:integer, gt?: 0)
        optional(:after).maybe(:integer, gteq?: 0)
        optional(:state).maybe(:string, included_in?: ResultPaneState::STATES)
        optional(:action_id).maybe(:integer, gt?: 0)
        optional(:input).maybe(:string, max_size?: AI::TextTransformRun::MAX_INPUT_LENGTH)
        optional(:retry_of).maybe(:string, :uuid_v4?)
      end

      rule(:project_id, :work_package_id) do
        key(:project_id).failure(:with_work_package) if values[:project_id] && values[:work_package_id]
      end

      rule(:type_id, :project_id) do
        key(:type_id).failure(:without_project) if values[:type_id].nil? != values[:project_id].nil?
      end

      rule(:retry_of, :action_id, :input) do
        key(:retry_of).failure(:with_action) if values[:retry_of] && (values[:action_id] || values[:input])
      end
    end
  end
end
