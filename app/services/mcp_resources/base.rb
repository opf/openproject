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
  class Base
    include APIV3Helper

    class << self
      def qualified_name
        "resources/#{name}"
      end

      def default_title(title = nil)
        @default_title = title if title.present?

        @default_title
      end

      def default_description(description = nil)
        @default_description = description if description.present?

        @default_description
      end

      def name(name = nil)
        @name = name if name.present?

        @name
      end

      def uri(suffix = nil)
        @uri_suffix = suffix if suffix.present?
        return nil if @uri_suffix.nil?

        "#{Setting.protocol}://#{Setting.host_name}#{@uri_suffix}"
      end

      def uri_template(suffix = nil)
        @template_suffix = suffix if suffix.present?
        return nil if @template_suffix.nil?

        UriTemplate.new("#{Setting.protocol}://#{Setting.host_name}#{@template_suffix}")
      end

      def resource
        raise ArgumentError, "#{self.class.name} can't be used as resource, uri is blank" if uri.blank?

        config = McpConfiguration.find_by(identifier: qualified_name)
        return nil if config.nil?

        MCP::Resource.new(
          uri:,
          name:,
          title: config.title,
          description: config.description,
          mime_type: "application/json"
        )
      end

      def resource_template
        raise ArgumentError, "#{self.class.name} can't be used as resource_template, uri_template is blank" if uri_template.blank?

        config = McpConfiguration.find_by(identifier: qualified_name)
        return nil if config.nil?

        MCP::ResourceTemplate.new(
          uri_template:,
          name:,
          title: config.title,
          description: config.description,
          mime_type: "application/json"
        )
      end

      def read(uri)
        params = uri_template&.parse(uri) || {}
        new.read(**params)
      end
    end

    def current_user = ::User.current

    def read(**)
      raise NotImplemented, "#{self.class} needs to implement #read method"
    end
  end
end
