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

module Import
  class JiraServerVersion
    SUPPORTED_VERSIONS = Gem::Requirement.new(">= 8.14", "< 12")
    BASIC_AUTH_ONLY_VERSIONS = Gem::Requirement.new("< 9")

    def self.from_server_info(server_info)
      return new(nil) unless server_info.is_a?(Hash)

      version_numbers = Array(server_info["versionNumbers"]).join(".")
      new(version_numbers.presence || server_info["version"])
    end

    def initialize(raw_version)
      @raw_version = raw_version.to_s.strip
      @version = Gem::Version.new(@raw_version) if recognizable?
    end

    def status
      return :unknown if @version.nil?
      return :supported if SUPPORTED_VERSIONS.satisfied_by?(@version)

      :unsupported
    end

    def warning
      return if status == :supported

      I18n.t(:"admin.jira.server_version.#{status}", version: @raw_version)
    end

    def supports_auth_method?(auth_method)
      auth_method.to_s == "basic" || !requires_basic_auth?
    end

    def to_s
      @raw_version
    end

    private

    def requires_basic_auth?
      return false if @version.nil?

      BASIC_AUTH_ONLY_VERSIONS.satisfied_by?(@version)
    end

    def recognizable?
      @raw_version.present? && Gem::Version.correct?(@raw_version)
    end
  end
end
