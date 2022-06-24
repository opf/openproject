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
      ctime: 1655334567, mtime: 1655301234,
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
  describe '#call' do
    subject { instance.call }

    context 'with no connection to Nextcloud' do
      before do
        # Simulate a complete disconnection on both hosts
        stub_request(:any, host1).to_timeout
        stub_request(:any, host2).to_timeout
      end

      it 'leaves the list of file_links unchanged' do
        expect(subject).to be_a ServiceResult
        expect(subject.success).to be_falsey
        expect(subject.result).to eql file_links
        expect(subject.result[0].origin_permission).to eql nil
        expect(subject.result[1].origin_permission).to eql nil
      end
      # Test that no :shared_with_me appears
    end

    context 'with connection to Nextcloud1, permission from Nextcloud1 and some updates' do
      before do
        stub_request(:get, File.join(host1, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
          .to_return(status: 200, body: file_link1_200_json)
      end

      # Just test a single update (mtime). Detailed update testing is further below.
      it 'updates the file_link information' do
        expect(subject).to be_a ServiceResult
        expect(subject.success).to be_truthy
        expect(subject.result[0].origin_updated_at).to eql Time.at(1655301234) # updated
        expect(subject.result[1].origin_updated_at).to eql Time.at(1655322371) # remains the same
      end

      it 'updates the origin_permission' do
        expect(subject.success).to be_truthy
        expect(subject.result[0].origin_permission).to eql :view # updated
        expect(subject.result[1].origin_permission).to eql nil   # remains the same
      end
    end

    context 'with connection to Nextcloud, getting 403 for both FileLinks' do
      before do
        stub_request(:get, File.join(host1, '/ocs/v1.php/apps/integration_openproject/filesinfo'))
          .to_return(status: 200, body: file_link1_403_json)
      end

      it 'does not have origin_permission' do
        expect(subject.success).to be_truthy
        expect(subject.result[0].origin_permission).to eql :not_allowed
        expect(subject.result[1].origin_permission).to eql :not_allowed
      end
    end

    context 'with some FileLinks readable and other FileLinks not readable, ' do
      # ToDo Check that a Nextcloud response about a non-visible file is reflected in the permissions returned by API
    end

    context 'with expired OAuth2 token, refresh and updated information from Nextcloud' do
      # ToDo
    end

    context 'with expired OAuth2 token and refresh failed' do
      # ToDo -> Error
    end

    context 'with connection and updated information from Nextcloud' do
      # ToDo check that all these different fields are being updated
    end

    # ToDo:
    # - sync_single_file: Check for all different attributes
    # - Existing FileLink attributes should not be overwritte by nil
    # - creation_date and creation_user not overwritable
    # - Name may be overwritten by user with whom the FileLink has been shared
    # -
  end

  # Test the update of fields of a single FileLink based on information returned from Nextcloud.
  describe '#sync_single_file' do
    let(:file_link1_all_modified_hash) {
      {
        id: 24,
        status: "OK", statuscode: 200,
        ctime: 1755334567, mtime: 1755301234,
        mimetype: "application/text",
        name: "Readme.txt",
        owner_id: "fraber", owner_name: "fraber",
        size: 1270,
        trashed: true
      }
    }
    subject { instance.sync_single_file(file_link1, file_link1_all_modified_hash) }

    #    "ctime" : 0,               # Linux epoch file creation +overwrite
    #    "mtime" : 1655301278,      # Linux epoch file modification +overwrite
    #    "mimetype" : "application/pdf",  # +overwrite
    #    "name" : "Nextcloud Manual.pdf", # "Canonical" name, could changed by owner +overwrite
    #    "owner_id" : "admin",      # ID at Nextcloud side +overwrite
    #    "owner_name" : "admin",    # Name at Nextcloud side +overwrite
    #    "size" : 12706214,         # Not used yet in OpenProject +overwrite
    #    "status" : "OK",           # Not used yet
    #    "statuscode" : 200,        # Not used yet
    #    "trashed" : false          # ToDo: How to handle "trashed" files? -> delete from array of models, check not in CollectopmRepresenter
    # }
    fcontext 'with complete information to write (happy path)' do
      it 'updates all important fieldsleaves the list of file_links unchanged' do
        expect(subject).to be_a ::Storages::FileLink
        expect(subject.created_at).to eql Time.at(1755334567)
      end
      # Test that no :shared_with_me appears
    end
  end
end

#       t.references :creator,
#                    null: false,
#                    index: true,
#                    foreign_key: { to_table: :users }
#       t.bigint :container_id, null: false
#       t.string :container_type, null: false
#
#       t.string :origin_id
#       t.string :origin_name
#       t.string :origin_created_by_name
#       t.string :origin_last_modified_by_name
#       t.string :origin_mime_type
#       t.timestamp :origin_created_at
#       t.timestamp :origin_updated_at
#
#       t.timestamps
#
#       # i.e. show all file links per WP.
#       t.index %i[container_id container_type]
#       # i.e. show all work packages per file.
#       t.index %i[origin_id storage_id]
