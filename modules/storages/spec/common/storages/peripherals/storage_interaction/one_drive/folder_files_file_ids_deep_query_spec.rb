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

RSpec.describe Storages::Peripherals::StorageInteraction::OneDrive::FolderFilesFileIdsDeepQuery, :webmock do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:storage) { create(:sharepoint_dev_drive_storage, oauth_client_token_user: user) }
  let(:folder) { Storages::Peripherals::ParentFolder.new('/') }

  describe '#call' do
    it 'responds with correct parameters' do
      expect(described_class).to respond_to(:call)

      method = described_class.method(:call)
      expect(method.parameters).to contain_exactly(%i[keyreq storage], %i[keyreq folder])
    end

    context 'with outbound requests successful' do
      subject do
        described_class.call(storage:, folder:).result
      end

      context 'with parent folder being root', vcr: 'one_drive/folder_files_file_ids_deep_query_root' do
        it 'returns the file id dictionary' do
          expect(subject.transform_values(&:id))
            .to eq({
                     '/' => '01AZJL5PN6Y2GOVW7725BZO354PWSELRRZ',
                     '/Folder with spaces' => '01AZJL5PKU2WV3U3RKKFF2A7ZCWVBXRTEU',
                     '/Folder with spaces/very empty folder' => '01AZJL5PMGEIRPHZPHRRH2NM3D734VIR7H',
                     '/Folder with spaces/wordle1.png' => '01AZJL5PPMSBBO3R2BIZHJFCELSW3RP7GN',
                     '/Folder with spaces/wordle2.png' => '01AZJL5PIIFUD6A765KBAIAEMYACAFB2WP',
                     '/Folder with spaces/wordle3.png' => '01AZJL5PL4AUJEU43CQZFJKN7BQPRP3BLF',
                     '/Folder' => '01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR',
                     '/Folder/Images' => '01AZJL5PMIF7ND3KH6FVDLZYP3E36ERFGI',
                     '/Folder/Subfolder' => '01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG',
                     '/Folder/Ümlæûts' => '01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB',
                     '/Folder/Document.docx' => '01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU',
                     '/Folder/Sheet.xlsx' => '01AZJL5PLB7SH7633RMBHIH6KVMQRU4RJS',
                     '/Folder/Images/der_laufende.jpeg' => '01AZJL5PLZFCARRQIDFJF36UL2WTLXTNSY',
                     '/Folder/Images/written_in_stone.webp' => '01AZJL5PLNCKWYI752YBHYYJ6RBFZWOZ46',
                     '/Folder/Subfolder/NextcloudHub.md' => '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA',
                     '/Folder/Subfolder/test.txt' => '01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ',
                     '/Folder/Ümlæûts/Anrüchiges deutsches Dokument.docx' => '01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE',
                     '/Permissions Folder' => '01AZJL5PN3LVLHH2RSZZDJ6ZFAD3OWSGYB'
                   })
        end
      end

      context 'with a given parent folder', vcr: 'one_drive/folder_files_file_ids_deep_query_parent_folder' do
        let(:folder) { Storages::Peripherals::ParentFolder.new('01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR') }

        it 'returns the file id dictionary' do
          expect(subject.transform_values(&:id))
            .to eq({
                     '/Folder' => '01AZJL5PMAXGDWAAKMEBALX4Q6GSN5BSBR',
                     '/Folder/Images' => '01AZJL5PMIF7ND3KH6FVDLZYP3E36ERFGI',
                     '/Folder/Subfolder' => '01AZJL5PPWP5UOATNRJJBYJG5TACDHEUAG',
                     '/Folder/Ümlæûts' => '01AZJL5PNQYF5NM3KWYNA3RJHJIB2XMMMB',
                     '/Folder/Document.docx' => '01AZJL5PJTICED3C5YSVAY6NWTBNA2XERU',
                     '/Folder/Sheet.xlsx' => '01AZJL5PLB7SH7633RMBHIH6KVMQRU4RJS',
                     '/Folder/Images/der_laufende.jpeg' => '01AZJL5PLZFCARRQIDFJF36UL2WTLXTNSY',
                     '/Folder/Images/written_in_stone.webp' => '01AZJL5PLNCKWYI752YBHYYJ6RBFZWOZ46',
                     '/Folder/Subfolder/NextcloudHub.md' => '01AZJL5PNCQCEBFI3N7JGZSX5AOX32Z3LA',
                     '/Folder/Subfolder/test.txt' => '01AZJL5PLOL2KZTJNVFBCJWFXYGYVBQVMZ',
                     '/Folder/Ümlæûts/Anrüchiges deutsches Dokument.docx' => '01AZJL5PNDURPQGKUSGFCJQJMNNWXKTHSE'
                   })
        end
      end
    end

    context 'with not existent parent folder', vcr: 'one_drive/folder_files_file_ids_deep_query_invalid_parent' do
      let(:folder) { Storages::Peripherals::ParentFolder.new('/I/just/made/that/up') }

      it 'must return not found' do
        result = described_class.call(storage:, folder:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:not_found) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end

    context 'with invalid oauth credentials', vcr: 'one_drive/folder_files_file_ids_deep_query_invalid_credentials' do
      before do
        unauthorized_http = OpenProject.httpx.with(headers: { authorization: "Bearer YouShallNotPass" })
        allow(Storages::Peripherals::StorageInteraction::Authentication)
          .to receive(:with_client_credentials)
                .and_yield(unauthorized_http)
      end

      it 'must return unauthorized' do
        result = described_class.call(storage:, folder:)
        expect(result).to be_failure
        expect(result.error_source).to be_a(described_class)

        result.match(
          on_failure: ->(error) { expect(error.code).to eq(:unauthorized) },
          on_success: ->(file_infos) { fail "Expected failure, got #{file_infos}" }
        )
      end
    end

    context 'with network errors' do
      before do
        request = HTTPX::Request.new(:get, 'https://my.timeout.org/')
        httpx_double = class_double(HTTPX, get: HTTPX::ErrorResponse.new(request, 'Timeout happens', {}))
        allow(Storages::Peripherals::StorageInteraction::Authentication)
          .to receive(:with_client_credentials)
                .and_yield(httpx_double)
      end

      it 'must return an error with wrapped network error response' do
        error = described_class.call(storage:, folder:)
        expect(error).to be_failure
        expect(error.result).to eq(:error)
        expect(error.error_payload).to be_a(HTTPX::ErrorResponse)
      end
    end
  end
end
