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

module OAuthConnectionsHelpers
  def mock_one_drive_authorization_validation(with: {})
    me_response = {
      businessPhones: [
        "+45 123 4567 8901"
      ],
      displayName: "Sheev Palpatine ",
      givenName: "Sheev",
      jobTitle: "Galactic Senator",
      mail: "palpatine@senate.com",
      mobilePhone: "+45 123 4567 8901",
      officeLocation: "500 Republica",
      preferredLanguage: "en-US",
      surname: "Palpatine",
      userPrincipalName: "palpatine@senate.com",
      id: "87d349ed-44d7-43e1-9a83-5f2406dee5bd"
    }.to_json

    stub = stub_request(:get, "https://graph.microsoft.com/v1.0/me")
      .to_return(status: 200, body: me_response, headers: { "Content-Type" => "application/json" })

    if with.present?
      stub.with(with)
    end
  end
end

RSpec.configure do |c|
  c.include OAuthConnectionsHelpers, :oauth_connection_helpers
end
