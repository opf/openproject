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
require 'webmock/rspec'

# The FileLinkSyncService takes an array of FileLink models and
# performs a REST call to a Nextcloud server to check which of the
# links are visible to the current user ("shared_with_me").
# We want to test that permissions are processed correctoy and also
# test the reaction to various types of network issues.
# This spec bears some similarities to the connection_manager_spec.rb.
describe ::Storages::FileLinkSyncService, type: :model do
  let(:user) { create :user }
  let(:role) { create(:existing_role, permissions: [:manage_file_links]) }
  let(:project) { create(:project, members: { user => role }) }
  let(:work_package) { create(:work_package, project:) }

  # We want to check the case of file_links from multiple storages
  let(:host1) { "http://172.16.146" }
  let(:host2) { "http://172.16.144" }
  let(:storage1) { create(:storage, host: host1) }
  let(:storage2) { create(:storage, host: host2) }
  let(:oauth_client1) { create(:oauth_client, integration: storage1) }
  let(:oauth_client2) { create(:oauth_client, integration: storage2) }
  let(:oauth_client_token1) { create(:oauth_client_token, oauth_client1:, user:) }
  let(:oauth_client_token2) { create(:oauth_client_token, oauth_client2:, user:) }
  let(:file_link1) { create(:file_link, origin_id: "24", origin_updated_at: Time.at(1655321371), storage: storage1, container: work_package) }
  let(:file_link2) { create(:file_link, origin_id: "12", origin_updated_at: Time.at(1655322371), storage: storage2, container: work_package) }

  let(:file_links) { [file_link1, file_link2] }
  let(:instance) { described_class.new(user:, file_links:) }

  let(:file_link1_200_json) {
    {
      id: 24,
      status: "OK", statuscode: 200,
      ctime: 0, mtime: 1655301234,
      mimetype: "application/pdf",
      name: "Nextcloud Manual.pdf",
      owner_id: "admin", owner_name: "admin",
      size: 12706214,
      trashed: false
    }.to_json
  }
  let(:file_link1_403_json) {
    {
      status: "Forbidden",
      statuscode: 403
    }.to_json
  }

  # Test the main function of the service, which is to
  # the OAuth2 provider URL (Nextcloud) according to RFC specs.
  describe '#call when disconnected to any Nextcloud instance' do
    subject { instance.call }

    fcontext 'with no connection to Nextcloud' do
      before do
        # Simulate a complete disconnection on both hosts
        stub_request(:any, host1).to_timeout
        stub_request(:any, host2).to_timeout
      end

      it 'leaves the list of file_links unchanged' do
        expect(subject).to be_a ServiceResult
        expect(subject.success).to be_falsey
        expect(subject.result).to eql file_links
        expect(subject.result[0].origin_permission).to eql :view

      end
      # Test that no :shared_with_me appears
    end

    context 'with connection to Nextcloud1, updates from Nextcloud1 and permission from Nextcloud1' do
      # Simulate a successful authorization and :shared_with_me data for file_link1
      before do
        stub_request(:get, File.join(host1, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
          .to_return(status: 200, body: file_link1_200_json)
      end

      it 'has a origin_permission link' do
        expect(subject.success).to be_truthy
        expect(subject.result[0].origin_permission).to eql :view
      end

      it 'updates the file_link information' do
        expect(subject).to be_a ServiceResult
        expect(subject.success).to be_truthy
        expect(subject.result[0].origin_updated_at).to eql Time.at(1655301234) # Check mtime update
      end
    end

    context 'with connection to Nextcloud, no updates, only file_link1 :shared_with_me' do
      before do
        file_link1_403_json = { status: "Forbidden", statuscode: 403 }.to_json
      end
    end

    context 'with connection and updated information from Nextcloud' do
      # ToDo check that all these different fields are being updated
    end

    context 'with expired OAuth2 token, refresh and updated information from Nextcloud' do
      # ToDo
    end

    context 'with expired OAuth2 token and refresh failed' do
      # ToDo -> Error
    end

    # ToDo:
    # - sync_single_file: Check for all different attributes
    # - Existing FileLink attributes should not be overwritte by nil
    # - creation_date and creation_user not overwritable
    # - Name may be overwritten by user with whom the FileLink has been shared
    # -

  end
end

