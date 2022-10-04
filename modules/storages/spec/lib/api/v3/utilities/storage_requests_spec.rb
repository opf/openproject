#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

require 'spec_helper'

describe API::V3::Utilities::StorageRequests, webmock: true do
  let(:user) { build_stubbed(:user) }

  let(:url) { 'https://example.com' }
  let(:origin_user_id) { 'admin' }
  let(:xml) do
    '<?xml version="1.0"?>' \
      '<d:multistatus xmlns:d="DAV:" ' \
      'xmlns:s="http://sabredav.org/ns" ' \
      'xmlns:oc="http://owncloud.org/ns" ' \
      'xmlns:nc="http://nextcloud.org/ns">' \
      '<d:response>' \
      '<d:href>/remote.php/dav/files/admin/</d:href>' \
      '<d:propstat>' \
      '<d:prop>' \
      '<d:getlastmodified>Tue, 06 Sep 2022 06:43:56 GMT</d:getlastmodified>' \
      '<oc:fileid>6</oc:fileid>' \
      '<oc:owner-display-name>admin</oc:owner-display-name>' \
      '<oc:size>24049442</oc:size>' \
      '</d:prop>' \
      '<d:status>HTTP/1.1 200 OK</d:status>' \
      '</d:propstat>' \
      '<d:propstat>' \
      '<d:prop>' \
      '<d:getcontenttype/>' \
      '</d:prop>' \
      '<d:status>HTTP/1.1 404 Not Found</d:status>' \
      '</d:propstat>' \
      '</d:response>' \
      '<d:response>' \
      '<d:href>/remote.php/dav/files/admin/Nextcloud%20Manual.pdf</d:href>' \
      '<d:propstat>' \
      '<d:prop>' \
      '<d:getcontenttype>application/pdf</d:getcontenttype>' \
      '<d:getlastmodified>Tue, 06 Sep 2022 06:43:56 GMT</d:getlastmodified>' \
      '<oc:fileid>7</oc:fileid>' \
      '<oc:owner-display-name>admin</oc:owner-display-name>' \
      '<oc:size>12764917</oc:size>' \
      '</d:prop>' \
      '<d:status>HTTP/1.1 200 OK</d:status>' \
      '</d:propstat>' \
      '</d:response>' \
      '<d:response>' \
      '<d:href>/remote.php/dav/files/admin/Nextcloud%20intro.mp4</d:href>' \
      '<d:propstat>' \
      '<d:prop>' \
      '<d:getcontenttype>video/mp4</d:getcontenttype>' \
      '<d:getlastmodified>Tue, 06 Sep 2022 06:43:56 GMT</d:getlastmodified>' \
      '<oc:fileid>13</oc:fileid>' \
      '<oc:owner-display-name>admin</oc:owner-display-name>' \
      '<oc:size>3963036</oc:size>' \
      '</d:prop>' \
      '<d:status>HTTP/1.1 200 OK</d:status>' \
      '</d:propstat>' \
      '</d:response>' \
      '</d:multistatus>'
  end

  let(:storage) do
    storage = instance_double(::Storages::Storage)
    allow(storage).to receive(:oauth_client).and_return(instance_double(OAuthClient))
    allow(storage).to receive(:provider_type).and_return(::Storages::Storage::PROVIDER_TYPE_NEXTCLOUD)
    allow(storage).to receive(:host).and_return(url)
    storage
  end

  let(:connection_manager) do
    connection_manager = instance_double(::OAuthClients::ConnectionManager)
    allow(connection_manager).to receive(:get_access_token).and_return(ServiceResult.success(result: access_token))
    allow(connection_manager).to receive(:with_refreshed_token).and_yield
    connection_manager
  end

  let(:access_token) do
    token = instance_double(OAuthClientToken)
    allow(token).to receive(:origin_user_id).and_return(origin_user_id)
    allow(token).to receive(:access_token).and_return('xyz')
    token
  end

  subject { described_class.new(storage:) }

  before do
    allow(::OAuthClients::ConnectionManager).to receive(:new).and_return(connection_manager)
    stub_request(:propfind, "#{url}/remote.php/dav/files/#{origin_user_id}/")
      .to_return(status: 207, body: xml, headers: {})
  end

  describe 'files_query' do
    describe 'with Nextcloud storage type selected' do
      it 'must return a list of files when called' do
        subject
          .files_query(user:)
          .match(
            on_success: ->(q) do
              result = q.call
              expect(result.success).to be_truthy
              expect(result.result.size).to eq(2)
            end,
            on_failure: ->(_) do
              raise "Files query could not be created."
            end
          )
      end

      # test if results are correct
    end

    describe 'with not supported storage type selected' do
      before do
        allow(storage).to receive(:provider_type).and_return('not_supported_storage_type'.freeze)
      end

      it 'must raise ArgumentError' do
        expect { subject.files_query(user:) }.to raise_error(ArgumentError)
      end
    end

    describe 'with missing OAuth token' do
      before do
        allow(connection_manager).to receive(:get_access_token).and_return(ServiceResult.failure)
      end

      it 'must return ":not_authorized" ServiceResult if OAuth token is missing' do
        expect(subject.files_query(user:)).to be_failure
      end
    end

    #
    # it 'must return ":not_authorized" ServiceResult if outbound request returns "401 Not Authorized"' do
    #
    # end
    #
    # it 'must return ":not_found" ServiceResult if outbound request cannot find ressource' do
    #
    # end
    #
    # it 'must return ":error" ServiceResult if outbound request is not successful' do
    #
    # end
  end
end
