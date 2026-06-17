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

module XWikiStubs
  def search_endpoint(linkable, provider:, number: 25)
    "#{provider.url}rest/openproject/links/workPackages/#{linkable.id}?number=#{number}"
  end

  def mentions_endpoint(linkable, provider:)
    "#{provider.url}rest/openproject/mentions?workPackage=#{linkable.id}"
  end

  def stub_canonical_page_info(identifier, uid:, title:, href:, provider:, token: "user-bearer-token")
    stub_xwiki_get("#{provider.url}rest/openproject/documents",
                   { "id" => uid, "title" => title, "xwikiAbsoluteUrl" => href },
                   token:,
                   query: { "docRef" => identifier })
  end

  def stub_search(search_results, provider:, linkable:, number: 25, token: "user-bearer-token")
    stub_xwiki_get(search_endpoint(linkable, provider:, number:), { "searchResults" => search_results }, token:)
  end

  def stub_mentions(search_results, provider:, linkable:, token: "user-bearer-token")
    stub_xwiki_get(mentions_endpoint(linkable, provider:), { "searchResults" => search_results }, token:)
  end

  private

  def stub_xwiki_get(url, body, token: "user-bearer-token", **with_opts)
    stub_request(:get, url)
      .with(headers: { "Authorization" => "Bearer #{token}" }, **with_opts)
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end
end
