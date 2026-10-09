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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module DynamicContentSecurityPolicy
  extend ActiveSupport::Concern

  included do
    before_action :add_hocuspocus_host_to_csp
    before_action :add_cable_host_to_csp
  end

  ##
  # Dynamically append sources to CSP directives
  # This replaces the secure_headers named append functionality
  def append_content_security_policy_directives(directives)
    policy = current_content_security_policy
    directives.each do |directive, source_values|
      current_value = policy.send(directive) || policy.directives["default-src"]
      new_values =
        if current_value == %w('none') # rubocop:disable Lint/PercentStringArray
          source_values.compact.uniq
        else
          (current_value + source_values).compact.uniq
        end

      policy.send(directive, *new_values)
      request.content_security_policy = policy
    end
  end

  private

  def add_hocuspocus_host_to_csp
    hocuspocus_url = Setting.collaborative_editing_hocuspocus_url
    if hocuspocus_url.present?
      uri = begin
        URI.parse(hocuspocus_url)
      rescue URI::InvalidURIError
        OpenProject.logger.info do
          "Setting.collaborative_editing_hocuspocus_url is set to an invalid URI: #{hocuspocus_url}"
        end
        nil
      end
      if uri.present?
        append_content_security_policy_directives(connect_src: ["#{uri.scheme}://#{host_with_port(uri)}"])
      end
    end
  end

  def add_cable_host_to_csp
    return unless OpenProject::LiveUpdates.enabled?

    uri = URI.parse(AnyCable.config.websocket_url)
    if uri.absolute?
      append_content_security_policy_directives(connect_src: ["#{uri.scheme}://#{host_with_port(uri)}"])
    end
  rescue URI::InvalidURIError
    OpenProject.logger.info { "AnyCable websocket_url is set to an invalid URI: #{AnyCable.config.websocket_url}" }
  end

  def host_with_port(uri)
    # Include port if it's not the default port for the scheme (necessary for local dev support)
    default_port = ["wss", "https"].include?(uri.scheme) ? 443 : 80
    uri.port && uri.port != default_port ? "#{uri.host}:#{uri.port}" : uri.host
  end
end
