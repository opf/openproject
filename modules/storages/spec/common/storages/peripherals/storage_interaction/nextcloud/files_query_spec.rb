# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
require_module_spec_helper

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery, :webmock do
  let(:storage) { create(:nextcloud_storage, :with_oauth_client) }
  let(:folder) { Storages::Peripherals::ParentFolder.new('/') }
  let(:user) { create(:user) }
  let(:token) do
    create(:oauth_client_token, user:, oauth_client: storage.oauth_client, origin_user_id: 'darth@vader with spaces')
  end

  let(:origin_user_id) { 'darth@vader with spaces' }
  let(:webdav_success_response) { create(:webdav_data, parent_path: '', root_path: '', origin_user_id:) }

  subject(:files_query) { described_class }

  before do
    uri = "#{storage.host}/remote.php/dav/files/darth@vader%20with%20spaces/"
    allow(Storages::Peripherals::StorageInteraction::Nextcloud::Util).to receive(:token).and_yield(token)
    stub_request(:propfind, uri).to_return(status: 207, body: webdav_success_response, headers: {})
  end

  it '.call requires 3 arguments: storage, user, and folder' do
    expect(described_class).to respond_to(:call)

    method = described_class.method(:call)
    expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq folder])
  end

  it 'returns a list of files and folders' do
    storage_files = files_query.call(storage:, folder:, user:).result
    expect(storage_files).to be_a(Storages::StorageFiles)

    expect(storage_files.files.size).to eq(4)
    expect(storage_files.ancestors.size).to eq(0)
    expect(storage_files.parent.location).to eq('/')

    mime_types = storage_files.files.map(&:mime_type).uniq!

    expect(mime_types).to include('application/pdf') # file
    expect(mime_types).to include('application/x-op-directory') # folder
  end

  it 'returns permissions for each' do
    storage_files = files_query.call(storage:, folder:, user:).result

    writeable_folder = storage_files.files.find { |file| file.mime_type == 'application/x-op-directory' }
    expect(writeable_folder.permissions).to match_array(%i[readable writeable])

    readonly_file = storage_files.files.find { |file| file.mime_type == 'application/pdf' }
    expect(readonly_file.permissions).to match_array(%i[readable])
  end

  context 'when requesting a sub-folder' do
    let(:folder) { Storages::Peripherals::ParentFolder.new('/Photos/Birds') }
    let(:webdav_subfolder_success_response) { create(:webdav_data, parent_path: folder.path, root_path: '', origin_user_id:) }

    before do
      uri = "#{storage.host}/remote.php/dav/files/darth@vader%20with%20spaces#{folder.path}"
      stub_request(:propfind, uri).to_return(status: 207, body: webdav_subfolder_success_response, headers: {})
    end

    subject(:query_result) { files_query.call(user:, storage:, folder:).result }

    it 'returns 2 ancestors' do
      ancestors = query_result.ancestors

      expect(ancestors.size).to eq(2)
      expect(ancestors.map(&:location)).to match_array(%w[/ /Photos])
      expect(ancestors.map(&:name)).to match_array(%w[/ Photos])
    end

    it 'returns the parent folder' do
      expect(query_result.parent.name).to eq('Birds')
      expect(query_result.parent.location).to eq('/Photos/Birds')
    end

    it 'lists the contents of the folder' do
      expect(query_result.files).to all(be_a(Storages::StorageFile))
      expect(query_result.files.size).to eq(4)
    end

    it 'the files "location" include the entire path and the file name' do
      expect(query_result.files.last.location).to eq("/Photos/Birds/Manual.pdf")
    end
  end

  context 'when the storage runs on a subfolder' do
    let(:storage) { create(:nextcloud_storage, :with_oauth_client, host: 'https://example.com/death_star_blueprints') }

    it 'just works' do
      storage_files = files_query.call(storage:, user:, folder:)

      expect(storage_files).to be_success
    end
  end

  describe 'with missing OAuth token' do
    before do
      allow(Storages::Peripherals::StorageInteraction::Nextcloud::Util)
        .to receive(:token)
              .and_return(ServiceResult.failure(result: :unauthorized,
                                                errors: Storages::StorageError.new(code: :unauthorized)))
    end

    it 'returns an ":unauthorized" ServiceResult' do
      result = files_query.call(folder:, user:, storage:)
      expect(result).to be_failure
      expect(result.errors.code).to be(:unauthorized)
    end
  end

  shared_examples_for 'outbound is failing' do |code = 500, symbol = :error|
    describe "with outbound request returning #{code}" do
      before do
        uri = "#{storage.host}/remote.php/dav/files/darth@vader%20with%20spaces/"
        stub_request(:propfind, uri).to_return(status: code)
      end

      it "must return :#{symbol} ServiceResult" do
        result = files_query.call(folder:, user:, storage:)
        expect(result).to be_failure
        expect(result.errors.code).to be(symbol)
      end
    end
  end

  include_examples 'outbound is failing', 404, :not_found
  include_examples 'outbound is failing', 401, :unauthorized
  include_examples 'outbound is failing', 500, :error
end
