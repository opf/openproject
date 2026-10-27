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

module Repositories
  class GitlabProvider < Provider
    store_attribute :options, :url, :string
    store_attribute :options, :gitlab_user_id, :integer
    store_attribute :options, :webhook_secret, :string

    def self.for_web_url(web_url)
      resource = URI.parse(web_url.to_s)
      all.find { it.serves?(resource) }
    rescue URI::InvalidURIError
      nil
    end

    def serves?(resource)
      base = URI.parse(url.to_s)

      base.host.present? &&
        origin(base) == origin(resource) &&
        "#{resource.path}/".start_with?("#{base.path.chomp('/')}/")
    rescue URI::InvalidURIError
      false
    end

    # TODO: move into registry-style query methods (like we did for storages and wikis)
    def branch_url(branch)
      "#{branch.project_web_url}/-/tree/#{branch.name}"
    end

    def new_merge_request_url(branch)
      query = { "merge_request[source_branch]" => branch.name }.to_query

      "#{branch.project_web_url}/-/merge_requests/new?#{query}"
    end
    # END: move into registry-style query methods

    private

    def origin(uri) = [uri.scheme, uri.host&.downcase, uri.port]
  end
end
