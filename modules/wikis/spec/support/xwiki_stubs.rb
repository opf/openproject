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

  def stub_canonical_page_info(identifier, uid:, title:, href:, provider:, token: "user-bearer-token")
    stub_request(:get, "#{provider.url}rest/openproject/documents")
      .with(query: { "docRef" => identifier },
            headers: { "Authorization" => "Bearer #{token}" })
      .to_return(status: 200,
                 body: { "id" => uid, "title" => title, "xwikiAbsoluteUrl" => href }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_search(search_results, provider:, linkable:, number: 25, token: "user-bearer-token")
    stub_request(:get, search_endpoint(linkable, provider:, number:))
      .with(headers: { "Authorization" => "Bearer #{token}" })
      .to_return(status: 200,
                 body: { "searchResults" => search_results }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end
end
