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

      params do
        required(:request_id).filled(:string, :uuid_v4?)
        required(:scope).filled(:string, included_in?: SCOPES)
        optional(:work_package_id).maybe(:integer, gt?: 0)
        optional(:project_id).maybe(:integer, gt?: 0)
        optional(:type_id).maybe(:integer, gt?: 0)
        optional(:after).maybe(:integer, gteq?: 0)
        optional(:action_id).maybe(:integer, gt?: 0)
        optional(:input).maybe(:string)
        optional(:retry_of).maybe(:string, :uuid_v4?)
      end

      rule(:project_id) do
        key.failure(:with_work_package) if value && values[:work_package_id]
      end

      rule(:type_id) do
        key.failure(:without_project) if value.nil? != values[:project_id].nil?
      end

      def self.keys
        schema.key_map.map { |key| key.name.to_sym }
      end
    end
  end
end
