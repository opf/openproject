# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FileInfoQuery, :vcr, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }

  subject { described_class.new(storage) }

  describe '#call' do
    it 'responds with correct parameters' do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq user], %i[keyreq file_id])
    end

    context 'without outbound request involved' do
      context 'with nil' do
        it 'returns an error' do
          result = subject.call(user:, file_id: nil)

          expect(result).to be_failure
          expect(result.error_source).to eq(described_class)
          expect(result.result).to eq(:error)
        end
      end
    end
  end

  context 'with outbound requests successful' do
    context 'with a file id requested', vcr: 'one_drive/file_info_query_success_file' do
      let(:file_id) { '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA' }

      # rubocop:disable RSpec/ExampleLength
      it 'must return the file information when called' do
        result = subject.call(user:, file_id:)
        expect(result).to be_success

        result.match(
          on_success: ->(file_info) do
            expect(file_info).to be_a(Storages::StorageFileInfo)
            expect(file_info.to_h)
              .to eq({
                       status: 'ok',
                       status_code: 200,
                       id: '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA',
                       name: 'NextcloudHub.md',
                       size: 1095,
                       mime_type: 'application/octet-stream',
                       created_at: Time.parse('2023-09-26T14:45:25Z'),
                       last_modified_at: Time.parse('2023-09-26T14:46:13Z'),
                       owner_name: 'Eric Schubert',
                       owner_id: '0a0d38a9-a59b-4245-93fa-0d2cf727f17a',
                       last_modified_by_name: 'Eric Schubert',
                       last_modified_by_id: '0a0d38a9-a59b-4245-93fa-0d2cf727f17a',
                       permissions: nil,
                       trashed: false,
                       location: '/Folder/Subfolder/NextcloudHub.md'
                     })
          end,
          on_failure: ->(error) { fail "Expected success, got #{error}" }
        )
      end
      # rubocop:enable RSpec/ExampleLength
    end

    context 'with a folder id requested', vcr: 'one_drive/file_info_query_success_folder' do
      let(:file_id) { '01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB' }

      # rubocop:disable RSpec/ExampleLength
      it 'must return the file information when called' do
        result = subject.call(user:, file_id:)
        expect(result).to be_success

        result.match(
          on_success: ->(file_info) do
            expect(file_info).to be_a(Storages::StorageFileInfo)
            expect(file_info.to_h)
              .to eq({
                       status: 'ok',
                       status_code: 200,
                       id: '01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB',
                       name: 'Ümlæûts',
                       size: 18007,
                       mime_type: 'application/x-op-directory',
                       created_at: Time.parse('2023-10-09T15:26:32Z'),
                       last_modified_at: Time.parse('2023-10-09T15:26:32Z'),
                       owner_name: 'Eric Schubert',
                       owner_id: '0a0d38a9-a59b-4245-93fa-0d2cf727f17a',
                       last_modified_by_name: 'Eric Schubert',
                       last_modified_by_id: '0a0d38a9-a59b-4245-93fa-0d2cf727f17a',
                       permissions: nil,
                       trashed: false,
                       location: '/Folder/Ümlæûts'
                     })
          end,
          on_failure: ->(error) { fail "Expected success, got #{error}" }
        )
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end

  context 'with outbound request returning not found', vcr: 'one_drive/file_info_query_one_not_found' do
    let(:file_id) { 'not_existent' }

    it 'must return not found' do
      result = subject.call(user:, file_id:)
      expect(result).to be_failure
      expect(result.error_source).to be_a(Storages::Peripherals::StorageInteraction::OneDrive::Internal::DriveItemQuery)

      result.match(
        on_failure: ->(error) { expect(error.code).to eq(:not_found) },
        on_success: ->(file_info) { fail "Expected failure, got #{file_info}" }
      )
    end
  end

  context 'with invalid oauth token', vcr: 'one_drive/file_info_query_invalid_token' do
    let(:file_id) { '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA' }

    before do
      token = build_stubbed(:oauth_client_token, oauth_client: storage.oauth_client)
      allow(Storages::Peripherals::StorageInteraction::OneDrive::Util)
        .to receive(:using_user_token)
              .and_yield(token)
    end

    it 'must return unauthorized' do
      result = subject.call(user:, file_id:)
      expect(result).to be_failure
      expect(result.error_source).to be_a(Storages::Peripherals::StorageInteraction::OneDrive::Internal::DriveItemQuery)

      result.match(
        on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
        on_success: ->(file_info) { fail "Expected failure, got #{file_info}" }
      )
    end
  end

  context 'with not existent oauth token' do
    let(:file_id) { '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA' }
    let(:user_without_token) { create(:user) }

    it 'must return unauthorized' do
      result = subject.call(user: user_without_token, file_id:)
      expect(result).to be_failure
      expect(result.error_source).to be_a(OAuthClients::ConnectionManager)

      result.match(
        on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
        on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
      )
    end
  end

  context 'with network errors' do
    let(:file_id) { '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA' }

    before do
      request = HTTPX::Request.new(:get, 'https://my.timeout.org/')
      httpx_double = class_double(HTTPX, get: HTTPX::ErrorResponse.new(request, 'Timeout happens', {}))

      allow(OpenProject).to receive(:httpx).and_return(httpx_double)
    end

    it 'must return an error with wrapped network error response' do
      error = subject.call(user:, file_id:)
      expect(error).to be_failure
      expect(error.result).to eq(:error)
      expect(error.error_payload).to be_a(HTTPX::ErrorResponse)
    end
  end
end
