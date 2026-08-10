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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Llm
  # Resolves a connection's api_format to the adapter that speaks it.
  #
  # There is no universal model-discovery standard, so each dialect needs its own
  # translation: OpenAI-compatible servers answer GET /models with data[].id,
  # Gemini uses /v1beta/models with richer metadata, Bedrock needs AWS signing
  # rather than a bearer token, and Azure indirects through deployment names.
  #
  # Only the OpenAI adapter is implemented. The seam exists so that adding one is
  # a new class rather than a migration.
  module Adapters
    class UnsupportedFormat < StandardError; end

    FORMATS = {
      "openai" => "Llm::Adapters::Openai"
    }.freeze

    def self.for(connection)
      class_name = FORMATS[connection.api_format.to_s]
      raise UnsupportedFormat, connection.api_format.to_s if class_name.nil?

      class_name.constantize.new(connection)
    end
  end
end
