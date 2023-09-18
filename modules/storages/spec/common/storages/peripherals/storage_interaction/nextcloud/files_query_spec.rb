# frozen_string_literal: true

#-- copyright
#++

require 'spec_helper'
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery, :webmock do
  let(:storage) { create(:nextcloud_storage, :with_oauth_client) }
  let(:user) { create(:user) }
  let(:token) do
    create(:oauth_client_token, user:, oauth_client: storage.oauth_client, origin_user_id: 'darth@vader with spaces')
  end

  let(:webdav_success_response) { create(:webdav_data, parent_path: parent, root_path:, origin_user_id:) }

  subject(:files_query) { described_class }

  it '.call requires 3 arguments: storage, user, and folder' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq folder])
  end

  context 'when outbound call is successful' do
    let(:parent) { '' }
    let(:root_path) { '' }
    let(:origin_user_id) { 'darth@vader with spaces' }
    let(:uri) { "#{storage.host}/remote.php/dav/files/darth@vader%20with%20spaces/" }

    before do
      allow(Storages::Peripherals::StorageInteraction::Nextcloud::Util).to receive(:token).and_yield(token)
      stub_request(:propfind, uri).to_return(status: 207, body: webdav_success_response, headers: {})
    end

    it 'returns a list of files and folders' do
      storage_files = files_query.call(storage:, folder: nil, user:).result
      expect(storage_files).to be_a(Storages::StorageFiles)

      expect(storage_files.files.size).to eq(4)
      expect(storage_files.ancestors.size).to eq(0)
      expect(storage_files.parent.location).to eq('/')
      expect(storage_files.files[0]).to have_attributes(
        id: '11',
        name: 'Folder1',
        mime_type: 'application/x-op-directory',
        permissions: include(:readable, :writeable)
      )
      expect(storage_files.files[1]).to have_attributes(mime_type: 'application/x-op-directory',
                                                        permissions: %i[readable])

      expect(storage_files.files[2]).to have_attributes(id: '12',
                                                        name: 'README.md',
                                                        mime_type: 'text/markdown',
                                                        permissions: include(
                                                          :readable, :writeable
                                                        ))

      expect(storage_files.files[3]).to have_attributes(mime_type: 'application/pdf',
                                                        permissions: %i[readable])
    end

    it 'returns permissions for each' do
      storage_files = files_query.call(storage:, folder: nil, user:).result

      storage_files.files.map(&:permissions)
    end
  end

  #       describe '#files_query' do
  #       let(:parent) { '' }
  #       let(:root_path) { '' }
  #       let(:origin_user_id) { 'darth@vader with spaces' }
  #       let(:xml) { create(:webdav_data, parent_path: parent, root_path:, origin_user_id:) }
  #       let(:url) { "https://example.com#{root_path}" }
  #       let(:request_url) do
  #         Storages::Peripherals::StorageInteraction::Nextcloud::Util.join_uri_path(
  #           url,
  #           "/remote.php/dav/files/",
  #           CGI.escapeURIComponent(origin_user_id),
  #           parent
  #         )
  #       end
  #
  #       context 'when outbound is success' do
  #         before do
  #           stub_request(:propfind, request_url).to_return(status: 207, body: xml, headers: {})
  #         end
  #
  #         describe 'with Nextcloud storage type selected' do
  #           it 'returns a list files directories with names and permissions' do
  #             result = registry.resolve('queries.nextcloud.files').call(storage:, folder: nil, user:)
  #             expect(result).to be_success
  #
  #             query_result = result.result
  #             expect(query_result.files.size).to eq(4)
  #             expect(query_result.ancestors.size).to eq(0)
  #             expect(query_result.parent).not_to be_nil
  #             expect(query_result.files[0]).to have_attributes(id: '11',
  #                                                              name: 'Folder1',
  #                                                              mime_type: 'application/x-op-directory',
  #                                                              permissions: include(:readable, :writeable))
  #             expect(query_result.files[1]).to have_attributes(mime_type: 'application/x-op-directory',
  #                                                              permissions: %i[readable])
  #             expect(query_result.files[2]).to have_attributes(id: '12',
  #                                                              name: 'README.md',
  #                                                              mime_type: 'text/markdown',
  #                                                              permissions: include(:readable, :writeable))
  #             expect(query_result.files[3]).to have_attributes(mime_type: 'application/pdf',
  #                                                              permissions: %i[readable])
  #           end
  #
  #           describe 'with origin user id containing whitespaces' do
  #             let(:origin_user_id) { 'my user' }
  #             let(:xml) { create(:webdav_data, origin_user_id:) }
  #
  #             it do
  #               result = registry.resolve('queries.nextcloud.files').call(folder: parent, user:, storage:)
  #               expect(result.result.files[0].location).to eq('/Folder1')
  #
  #               assert_requested(:propfind, request_url)
  #             end
  #           end
  #
  #           describe 'with parent query parameter' do
  #             let(:parent) { '/Photos/Birds' }
  #
  #             it do
  #               result = registry.resolve('queries.nextcloud.files').call(folder: parent, user:, storage:)
  #               expect(result.result.files[2].location).to eq('/Photos/Birds/README.md')
  #               expect(result.result.ancestors[0].location).to eq('/')
  #               expect(result.result.ancestors[1].location).to eq('/Photos')
  #
  #               assert_requested(:propfind, request_url)
  #             end
  #           end
  #
  #           describe 'with storage running on a sub path' do
  #             let(:root_path) { '/storage' }
  #
  #             it do
  #               result = registry.resolve('queries.nextcloud.files').call(folder: nil, user:, storage:)
  #               expect(result.result.files[2].location).to eq('/README.md')
  #               assert_requested(:propfind, request_url)
  #             end
  #           end
  #
  #           describe 'with storage running on a sub path and with parent parameter' do
  #             let(:root_path) { '/storage' }
  #             let(:parent) { '/Photos/Birds' }
  #
  #             it do
  #               result = registry.resolve('queries.nextcloud.files').call(folder: parent, user:, storage:)
  #
  #               expect(result.result.files[2].location).to eq('/Photos/Birds/README.md')
  #               assert_requested(:propfind, request_url)
  #             end
  #           end
  #         end
  #
  #         describe 'with not supported storage type selected' do
  #           before do
  #             allow(storage).to receive(:provider_type).and_return('not_supported_storage_type')
  #           end
  #
  #           it 'must raise ArgumentError' do
  #             expect { registry.resolve('queries.nextcloud.files').call(storage:) }.to raise_error(ArgumentError)
  #           end
  #         end
  #
  #         describe 'with missing OAuth token' do
  #           before do
  #             instance = instance_double(OAuthClients::ConnectionManager)
  #             allow(OAuthClients::ConnectionManager).to receive(:new).and_return(instance)
  #             allow(instance).to receive(:get_access_token).and_return(ServiceResult.failure)
  #           end
  #
  #           it 'must return ":not_authorized" ServiceResult' do
  #             result = registry.resolve('queries.nextcloud.files').call(folder: parent, user:, storage:)
  #             expect(result).to be_failure
  #             expect(result.errors.code).to be(:not_authorized)
  #           end
  #         end
  #       end
  #
  #       shared_examples_for 'outbound is failing' do |code = 500, symbol = :error|
  #         describe "with outbound request returning #{code}" do
  #           before do
  #             stub_request(:propfind, request_url).to_return(status: code)
  #           end
  #
  #           it "must return :#{symbol} ServiceResult" do
  #             result = registry.resolve('queries.nextcloud.files').call(folder: parent, user:, storage:)
  #             expect(result).to be_failure
  #             expect(result.errors.code).to be(symbol)
  #           end
  #         end
  #       end
  #
  #       include_examples 'outbound is failing', 404, :not_found
  #       include_examples 'outbound is failing', 401, :not_authorized
  #       include_examples 'outbound is failing', 500, :error
  #     end
end
