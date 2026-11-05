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

module TestManagement
  module Automation
    class ConnectionResolver
      Plan = Struct.new(:connection, :mode, :target_run, keyword_init: true) do
        def new_iteration? = mode == "new_iteration"
      end

      def initialize(project:, options:, warnings: [])
        @project = project
        @options = options
        @warnings = warnings
      end

      def call
        connection = explicit || detected
        Plan.new(connection:,
                 mode: options.mode || connection&.ingest_mode || "new_run",
                 target_run: options.target_run || connection&.target_run_name)
      end

      private

      attr_reader :project, :options, :warnings

      def explicit # rubocop:disable Metrics/AbcSize
        ref = options.connection_ref
        return nil if ref.blank?

        connection = CiConnection.lookup(project, ref)
        raise Error.new(:unprocessable, "Unknown CI connection \"#{ref}\" in this project.") unless connection
        raise Error.new(:unprocessable, "CI connection \"#{connection.name}\" is inactive.") unless connection.active?

        repo = options.ci["repository"]
        if repo.present? && !connection.matches?(options.ci["provider"].presence || connection.provider, repo)
          warnings << { "code" => "connection_repository_mismatch", "connection" => connection.name, "repository" => repo }
        end
        connection
      end

      def detected
        connection = CiConnection.detect(project, options.ci["provider"], options.ci["repository"])
        return nil unless connection

        return connection if connection.active?

        warnings << { "code" => "connection_inactive", "connection" => connection.name }
        nil
      end
    end
  end
end
