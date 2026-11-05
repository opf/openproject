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

module API
  module V3
    module TestManagement
      module CiConnectionHelpers
        ATTRIBUTE_MAP = {
          "name" => :name,
          "provider" => :provider,
          "repository" => :repository,
          "ingestMode" => :ingest_mode,
          "targetRunName" => :target_run_name,
          "active" => :active,
          "token" => :token,
          "removeToken" => :remove_token,
          "workflow" => :workflow,
          "ref" => :trigger_ref
        }.freeze
        BOOLEAN_KEYS = %w[active removeToken].freeze

        def ci_connection_attributes
          body = request_body
          attributes_from(ATTRIBUTE_MAP, body).tap do
            body.slice(*ATTRIBUTE_MAP.keys).each do |key, value|
              next if value.nil? || (BOOLEAN_KEYS.include?(key) ? [true, false].include?(value) : value.is_a?(String))

              raise ::API::Errors::UnprocessableContent.new("#{key} has an invalid type.")
            end
          end
        end

        def visible_ci_connection!(id, permissions)
          connection = ::TestManagement::CiConnection.includes(:project).find_by(id:)
          raise ::API::Errors::NotFound.new unless connection && allowed_any?(permissions, connection.project)

          connection
        end
      end
    end
  end
end
