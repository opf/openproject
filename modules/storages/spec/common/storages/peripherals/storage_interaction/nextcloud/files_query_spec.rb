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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::FilesQuery, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) do
    create(:nextcloud_storage_with_local_connection, :as_not_automatically_managed, oauth_client_token_user: user)
  end
  let(:folder) { Storages::Peripherals::ParentFolder.new('/') }

  describe '#call' do
    it 'responds with correct parameters' do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq folder])
    end

    context 'with outbound requests successful' do
      context 'with parent folder being root', vcr: 'nextcloud/files_query_root' do
        # rubocop:disable RSpec/ExampleLength
        it 'returns a StorageFiles object for root' do
          storage_files = described_class.call(storage:, user:, folder:).result

          expect(storage_files).to be_a(Storages::StorageFiles)
          expect(storage_files.ancestors).to be_empty
          expect(storage_files.parent.name).to eq("Root")

          expect(storage_files.files.size).to eq(10)
          expect(storage_files.files[0].to_h)
            .to eq({
                     id: '45',
                     name: 'Documents',
                     size: 1107988,
                     created_at: nil,
                     created_by_name: 'admin',
                     last_modified_at: '2023-10-16T13:26:30Z',
                     last_modified_by_name: nil,
                     location: '/Documents',
                     mime_type: 'application/x-op-directory',
                     permissions: %i[readable writeable]
                   })
          expect(storage_files.files[6].to_h)
            .to eq({
                     id: '52',
                     name: 'Reasons to use Nextcloud.pdf',
                     size: 976625,
                     created_at: nil,
                     created_by_name: 'admin',
                     last_modified_at: '2023-07-27T13:30:24Z',
                     last_modified_by_name: nil,
                     location: '/Reasons%20to%20use%20Nextcloud.pdf',
                     mime_type: 'application/pdf',
                     permissions: %i[readable writeable]
                   })
          expect(storage_files.files[5].to_h)
            .to eq({
                     id: '713',
                     name: 'Readme.md',
                     size: 554,
                     created_at: nil,
                     created_by_name: 'admin',
                     last_modified_at: '2023-11-28T14:29:59Z',
                     last_modified_by_name: nil,
                     location: '/Readme.md',
                     mime_type: 'text/markdown',
                     permissions: %i[readable writeable]
                   })
        end
        # rubocop:enable RSpec/ExampleLength
      end

      context 'with a given parent folder', vcr: 'nextcloud/files_query_parent_folder' do
        let(:folder) { Storages::Peripherals::ParentFolder.new('/Documents/New Requests') }

        subject do
          described_class.call(storage:, user:, folder:).result
        end

        # rubocop:disable RSpec/ExampleLength
        it 'returns the files content' do
          expect(subject.files.size).to eq(2)
          expect(subject.files.map(&:to_h))
            .to eq([
                     {
                       id: '738',
                       name: 'request_001.md',
                       size: 16,
                       created_at: nil,
                       created_by_name: 'admin',
                       last_modified_at: '2023-11-28T14:39:34Z',
                       last_modified_by_name: nil,
                       location: '/Documents/New%20Requests/request_001.md',
                       mime_type: 'text/markdown',
                       permissions: %i[readable writeable]
                     }, {
                       id: '740',
                       name: 'request_002.md',
                       size: 19,
                       created_at: nil,
                       created_by_name: 'admin',
                       last_modified_at: '2023-11-28T14:39:58Z',
                       last_modified_by_name: nil,
                       location: '/Documents/New%20Requests/request_002.md',
                       mime_type: 'text/markdown',
                       permissions: %i[readable writeable]
                     }
                   ])
        end
        # rubocop:enable RSpec/ExampleLength

        it 'returns ancestors with a forged id' do
          expect(subject.ancestors.map { |a| { id: a.id, name: a.name, location: a.location } })
            .to eq([
                     {
                       id: '8a5edab282632443219e051e4ade2d1d5bbc671c781051bf1437897cbdfea0f1',
                       name: 'Root',
                       location: '/'
                     }, {
                       id: '4eb3246b9f5e1daf394b0ab4cfb9a640978465a028a6bf0d2ad561b7a815c8a1',
                       name: 'Documents',
                       location: '/Documents'
                     }
                   ])
        end

        it 'returns the parent itself' do
          expect(subject.parent.id).to eq('737')
          expect(subject.parent.name).to eq('New Requests')
          expect(subject.parent.location).to eq('/Documents/New%20Requests')
        end
      end

      context 'with parent folder being empty', vcr: 'nextcloud/files_query_empty_folder' do
        let(:folder) { Storages::Peripherals::ParentFolder.new('/Photos/todo') }

        it 'returns an empty StorageFiles object with parent and ancestors' do
          storage_files = described_class.call(storage:, user:, folder:).result

          expect(storage_files).to be_a(Storages::StorageFiles)
          expect(storage_files.files).to be_empty
          expect(storage_files.parent.id).to eq('760')
          expect(storage_files.ancestors.map(&:name)).to eq(%w[Root Photos])
        end
      end
    end

    context 'with not existent parent folder', vcr: 'nextcloud/files_query_invalid_parent' do
      let(:folder) { Storages::Peripherals::ParentFolder.new('/I/just/made/that/up') }

      it 'must return not found' do
        result = described_class.call(storage:, user:, folder:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:not_found) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end

    context 'with invalid oauth token', vcr: 'nextcloud/files_query_invalid_token' do
      before do
        token = build_stubbed(:oauth_client_token, oauth_client: storage.oauth_client)
        allow(Storages::Peripherals::StorageInteraction::Nextcloud::Util)
          .to receive(:token).and_yield(token)
      end

      it 'must return unauthorized' do
        result = described_class.call(storage:, user:, folder:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end

    context 'with not existent oauth token' do
      let(:user_without_token) { create(:user) }

      it 'must return unauthorized' do
        result = described_class.call(storage:, user: user_without_token, folder:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(OAuthClients::ConnectionManager)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end
  end
end
