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

RSpec.describe Storages::Peripherals::StorageInteraction::Nextcloud::CopyTemplateFolderCommand, webmock: true do
  using Storages::Peripherals::ServiceResultRefinements

  let(:user) { create(:user) }
  let(:url) { 'https://example.com' }
  let(:origin_user_id) { 'OpenProject' }
  let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: url, password: 'OpenProjectSecurePassword') }

  subject { described_class.new(storage) }

  describe '#call' do
    context 'when the source path is blank' do
      it 'returns an error' do
        result = subject.call(source_path: '', destination_path: 'destination')

        expect(result).to be_failure
        expect(result.errors.log_message).to eq('Source and destination paths must be present.')
      end
    end

    context 'when the destination path is blank' do
      it 'returns an error' do
        result = subject.call(source_path: 'source', destination_path: '')

        expect(result).to be_failure
        expect(result.errors.log_message).to eq('Source and destination paths must be present.')
      end
    end

    context 'when the source path is not blank' do
      context 'when the destination path is not blank' do
        let(:source_path) { 'source' }
        let(:destination_path) { 'destination' }
        let(:source_url) { "#{url}/remote.php/dav/files/#{CGI.escape(origin_user_id)}/#{source_path}" }
        let(:destination_url) { "#{url}/remote.php/dav/files/#{CGI.escape(origin_user_id)}/#{destination_path}" }

        context 'when the destination exsists' do
          before do
            stub_request(:head, destination_url).to_return(status: 200)
          end

          it 'returns an error' do
            result = subject.call(source_path:, destination_path:)

            expect(result).to be_failure
            expect(result.errors.log_message).to eq('Destination folder already exists.')
          end
        end

        context 'when the destination does not exist' do
          before do
            stub_request(:head, destination_url).to_return(status: 404)
          end

          context 'when the folder is copied successfully' do
            before do
              stub_request(:copy, source_url).to_return(status: 201)
            end

            it 'must be successful' do
              result = subject.call(source_path:, destination_path:)

              expect(result).to be_success
            end
          end

          context 'when the folder is not copied successfully' do
            before do
              body = <<~XML
                <?xml version="1.0" encoding="utf-8"?>
                <d:error
                  xmlns:d="DAV:"
                  xmlns:s="http://sabredav.org/ns">
                  <s:exception>Sabre\\DAV\\Exception\\Conflict</s:exception>
                  <s:message>The destination node is not found</s:message>
                </d:error>
              XML
              stub_request(:copy, source_url).to_return(status: 409, body:)
            end

            it 'must fail with :conflict' do
              result = subject.call(source_path:, destination_path:)

              expect(result).to be_failure
              expect(result.errors.code).to eq(:conflict)
            end
          end
        end
      end
    end
  end
end
