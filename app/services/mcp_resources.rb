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

module McpResources
  class << self
    def register(*resources)
      resources.each { |r| all << r }
    end

    def all
      @all ||= []
    end

    def enabled
      McpConfiguration.where(enabled: true).pluck(:identifier).filter_map { |name| resources_by_name[name] }
    end

    def resources_by_name
      @resources_by_name ||= all.index_by(&:qualified_name)
    end

    def enabled_mcp_resources
      McpConfiguration.where(enabled: true).filter_map do |config|
        res = resources_by_name[config.identifier]
        next unless res&.uri

        res.resource(title: config.title, description: config.description)
      end
    end

    def enabled_mcp_resource_templates
      McpConfiguration.where(enabled: true).filter_map do |config|
        res = resources_by_name[config.identifier]
        next unless res&.uri_template

        res.resource_template(title: config.title, description: config.description)
      end
    end

    def read_resource(uri)
      content = read_resource_content(uri)
      return [] if content.nil?

      [
        format_json_resource(uri, content)
      ]
    end

    def read_resource_content(uri, resources_considered: enabled)
      resource_class = resources_considered.find { |r| r.uri == uri || r.uri_template&.match?(uri) }
      resource_class&.read(uri)
    end

    def format_json_resource(uri, content)
      { uri:, mimeType: "application/json", text: content.to_json }
    end
  end
end
