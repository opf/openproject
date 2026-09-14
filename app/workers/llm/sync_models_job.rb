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
  # Refreshes the cached model catalogue out of band.
  #
  # Used by the environment seeder, which must not block on -- or fail because of
  # -- an LLM server that has not finished starting.
  class SyncModelsJob < ApplicationJob
    class SyncFailed < StandardError; end

    # The usual reason for a failure here is the startup race with the LLM
    # sidecar this job exists for, so a failed sync retries with backoff rather
    # than leaving the provisioned connection without its catalogue.
    retry_on SyncFailed, wait: :polynomially_longer, attempts: 10

    def perform
      connection = LlmConnection.first
      return if connection.nil? || !connection.configured?

      result = LlmConnections::SyncModelsService.new(connection).call
      raise SyncFailed, result.errors.to_s unless result.success?
    end
  end
end
